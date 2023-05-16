provider "mongodbatlas" {
  public_key  = var.atlas_access.public_key
  private_key = var.atlas_access.private_key
}

provider "aws" {
  region     = var.aws_access.aws_region
  access_key = var.aws_access.access_key
  secret_key = var.aws_access.secret_key
  token      = var.aws_access.token
}

resource "mongodbatlas_project" "project" {
  name   = var.project.name
  org_id = var.project.org_id
}

/*
resource "mongodbatlas_database_user" "dbuser" {
  depends_on = [mongodbatlas_project.project]

  username           = var.dbuser.name
  password           = var.dbuser.password
  auth_database_name = var.dbuser.auth_database_name
  project_id         = mongodbatlas_project.project.id
  roles {
    role_name     = var.dbuser.role_name
    database_name = var.dbuser.database_name
  }
  scopes {
    name = var.dbuser.scope_name
    type = var.dbuser.scope_type
  }
}
*/

resource "mongodbatlas_network_container" "network_container" {
  depends_on = [mongodbatlas_project.project]

  project_id       = mongodbatlas_project.project.id
  provider_name    = "AWS"
  atlas_cidr_block = var.network_container.atlas_cidr_block
  region_name      = var.network_container.region
}


resource "mongodbatlas_network_peering" "vpc_peering" {
  depends_on = [mongodbatlas_network_container.network_container]

  project_id             = mongodbatlas_project.project.id
  accepter_region_name   = var.aws_access.aws_region
  container_id           = mongodbatlas_network_container.network_container.container_id
  provider_name          = "AWS"
  route_table_cidr_block = var.aws_vpc_peering.route_table_cidr_block
  vpc_id                 = var.aws_vpc_peering.vpc_id
  aws_account_id         = var.aws_vpc_peering.aws_account_id
}

#After the request is accepted it still requires few mins to be acknowledged in Atlas as "Available"
resource "aws_vpc_peering_connection_accepter" "auto_peering_accepter" {
  depends_on = [mongodbatlas_network_peering.vpc_peering]

  vpc_peering_connection_id = mongodbatlas_network_peering.vpc_peering.connection_id
  auto_accept               = true
}

resource "mongodbatlas_privatelink_endpoint" "endpoint" {
  depends_on = [mongodbatlas_network_container.network_container]

  project_id    = mongodbatlas_project.project.id
  provider_name = "AWS"
  region        = var.aws_endpoint_settings.region
}

resource "aws_vpc_endpoint" "ptfe_service" {
  depends_on         = [mongodbatlas_privatelink_endpoint.endpoint]
  vpc_id             = var.aws_endpoint_settings.vpc_id
  service_name       = mongodbatlas_privatelink_endpoint.endpoint.endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [var.aws_endpoint_settings.subnet_id]
  security_group_ids = [var.aws_endpoint_settings.security_group_id]
}

resource "mongodbatlas_privatelink_endpoint_service" "endpoint_service" {
  depends_on          = [aws_vpc_endpoint.ptfe_service]
  project_id          = mongodbatlas_privatelink_endpoint.endpoint.project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.endpoint.private_link_id
  endpoint_service_id = aws_vpc_endpoint.ptfe_service.id
  provider_name       = "AWS"
  timeouts {
    create = "30m"
    delete = "20m"
  }
}

# Create multiple Atlas Clusters in the current Project
module "Cluster" {
  depends_on = [ mongodbatlas_network_container.network_container ]
  for_each   = var.atlas_clusters
  source     = "./modules/Cluster"

  name                        = each.key
  project_id                  = mongodbatlas_project.project.id
  mongo_db_major_version      = each.value["mongo_db_major_version"]
  provider_name               = each.value["provider_name"]
  region_name                 = each.value["region_name"]
  provider_instance_size_name = each.value["provider_instance_size_name"]
  disk_size_gb                = each.value["disk_size_gb"]
  cloud_backup                = each.value["cloud_backup"]
}

# Create multiple DB Users for a specfic Cluster, using Scope
# Each user is created against a specified DB (or "admin" for all), with multiple roles and scopes

module "DBUser" {
# Note: line below is hardcoded for "PROD"
  depends_on = [mongodbatlas_project.project]
  for_each   = var.dbusers_for_cluster
  source     = "./modules/DBUser"

  username           = each.value["username"]
  password           = each.value["password"]
  project_id         = mongodbatlas_project.project.id
  auth_database_name = each.value["auth_database_name"]
  roles              = each.value["roles"]
  scopes             = each.value["scopes"]
}

# Example is set up to create snapshot immediately after cluster is created
# Example does not populate data in orginal cluster before snapshot
# Hardcoded to "PROD" Cluster
resource "mongodbatlas_cloud_backup_snapshot" "snapshot" {
  depends_on        = [module.Cluster["PROD"].mongodbatlas_cluster]
  count             = var.snapshot.enable_snapshot == true ? 1 : 0
  project_id        = mongodbatlas_project.project.id
  cluster_name      = "PROD"
  description       = var.snapshot.description
  retention_in_days = var.snapshot.retention_in_days
}

# Example is set up to such that cluster and target_cluster are in the same Project
# Example is set up to restore immediately after snapshot is created
resource "mongodbatlas_cloud_backup_snapshot_restore_job" "restore_job" {
  depends_on   = [mongodbatlas_cloud_backup_snapshot.snapshot]
  count        = var.restore_job.enable_restore == true ? 1 : 0
  project_id   = mongodbatlas_cloud_backup_snapshot.snapshot[0].project_id
  cluster_name = mongodbatlas_cloud_backup_snapshot.snapshot[0].cluster_name
  snapshot_id  = mongodbatlas_cloud_backup_snapshot.snapshot[0].snapshot_id
  delivery_type_config {
    target_project_id = mongodbatlas_cloud_backup_snapshot.snapshot[0].project_id
    # this should work, but doesn't (so we hardcode):
    #      target_cluster_name = module.cluster["RESTORE"].mongodbatlas_cluster.cluster.name
    target_cluster_name = "RESTORE"
    automated           = var.restore_job.delivery_type_config.automated
  }
}

resource "mongodbatlas_cloud_provider_access_setup" "setup_only" {
  depends_on    = [mongodbatlas_project.project]
  project_id    = mongodbatlas_project.project.id
  provider_name = "AWS"
}

resource "mongodbatlas_cloud_provider_access_authorization" "auth_role" {
  depends_on = [mongodbatlas_cloud_provider_access_setup.setup_only]
  project_id = mongodbatlas_cloud_provider_access_setup.setup_only.project_id
  role_id    = mongodbatlas_cloud_provider_access_setup.setup_only.role_id

  aws {
    iam_assumed_role_arn = aws_iam_role.test_role.arn
  }
}

resource "mongodbatlas_encryption_at_rest" "test" {
  depends_on = [mongodbatlas_project.project]
  project_id = mongodbatlas_project.project.id

  aws_kms_config {
    enabled                = true
    customer_master_key_id = var.kms_key.customer_master_key
    region                 = var.kms_key.atlas_region
    role_id                = mongodbatlas_cloud_provider_access_authorization.auth_role.role_id
  }

}
