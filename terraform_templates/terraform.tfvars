# Must customize following fields
atlas_access = {
  public_key  = "" # From Atlas Project Public Key
  private_key = "" # From Atlas Project Private API Key
}

# Must customize following fields
aws_access = {
  aws_region = "" # From AWS					  
  access_key = "" # From AWS
  secret_key = "" # From AWS
  token = "" # From AWS (if required)
}

# Must customize following fields
aws_vpc_peering = {
  route_table_cidr_block = "" 
  vpc_id = "" # From existing AWS VPC
  aws_account_id = "" # From AWS Account
}

# Must customize following fields
aws_endpoint_settings = {
  region = "" 
  vpc_id = "" # From existing AWS VPC
  subnet_id = "" # From existing AWS subnet
  security_group_id = "" # From existing AWS Security Group
}

# Must customize following fields
project = {
  name   = "" # Provide name of desired Project to create
  org_id = "" # Existing Atlas Org ID
}

# Must customize following fields
network_container = {
  atlas_cidr_block = ""
  region           = ""
}

# Cluster-specific DB users
dbuser = {
  name     = "" # Must customize
  password = "" # Must customize
  auth_database_name = "admin"
  role_name     = "atlasAdmin"
  database_name     = "admin"
  scope_name = "PROD"
  scope_type = "CLUSTER"
}

# Must customize following fields
atlas_clusters = {
  DEV = {
    project_id                  = " "
    mongo_db_major_version      = ""
    provider_name               = "AWS"
    region_name                 = ""
    provider_instance_size_name = ""
    disk_size_gb                = 0
    cloud_backup                = false
  }
  QA = {
    project_id                  = " "
    mongo_db_major_version      = "5.0"
    provider_name               = "AWS"
    region_name                 = "US_EAST_1"
    provider_instance_size_name = "M20"
    disk_size_gb                = 20
    cloud_backup                = false
  }
  PROD = {
    project_id             = " "
    mongo_db_major_version = "5.0"
    provider_name          = "AWS"
    region_name            = "US_EAST_1"
    provider_instance_size_name   = "M30"
    disk_size_gb                = 30
    cloud_backup                = true
  }
  RESTORE = {
    project_id             = " "
    mongo_db_major_version = "5.0"
    provider_name          = "AWS"
    region_name            = "US_EAST_1"
    provider_instance_size_name   = "M30"
    disk_size_gb                = 30
    cloud_backup                = false
  }
}

# Structure to specify multiple database users again a single existing Cluster in an existing Project
# Supports multiple roles and scopes
dbusers_for_cluster = {
     DBADMIN_USER = {
        username                       = "demodbAdmin"
        password                       = "NotSoCommonPass123"
        auth_database_name             = "admin"
        project_id                     = ""
        roles = [
           {
              role_name                   = "dbAdmin"
              database_name               = "admin"
           }
        ]
        scopes = [
           {
              name                        = "PROD"
              type                        = "CLUSTER"
           }
        ]
     }
     RO_DATA_USER = {
        username                       = "demoReadOnly"
        password                       = "NotSoCommonPass123"
        auth_database_name             = "admin"
        project_id                     = ""
        roles = [
           {
              role_name                   = "read"
              database_name               = "db1"
           },
           {
              role_name                   = "read"
              database_name               = "db2"
           }
        ]
        scopes = [
           {
              name                        = "PROD"
              type                        = "CLUSTER"
           }
        ]
     }
     RW_DATA_USER = {
        username                       = "demoReadWrite"
        password                       = "NotSoCommonPass123"
        auth_database_name             = "admin"
        project_id                     = ""
        roles = [
           {
              role_name                   = "readWrite"
              database_name               = "db3"
           }
        ] 
        scopes = [
           {
              name                        = "PROD"
              type                        = "CLUSTER"
           }
        ]
     }
}

snapshot = {
  project_id        = ""
  cluster_name      = ""
  description       = "Test Snapshot for Terraform Testing"
  retention_in_days = 1
  enable_snapshot   = true
}

restore_job = {
  project_id   = ""
  cluster_name = ""
  snapshot_id  = ""
  delivery_type_config = {
    automated           = true
    target_project_id   = ""
    target_cluster_name = ""
  }
  enable_restore = true
}

kms_key = {
  atlas_region = "US_EAST_1"
  customer_master_key = "17c87909-f832-4c6c-be26-08d0b09fe227" # Must customize from existing AWS KMS Key
}
