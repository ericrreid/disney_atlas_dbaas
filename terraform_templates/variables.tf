variable "atlas_access" {
  type = object(
    {
      public_key  = string
      private_key = string
    }
  )
}

variable "aws_access" {
  type = object(
    {
      aws_region = string
      access_key = string
      secret_key = string
      token      = string
    }
  )
}

variable "aws_vpc_peering" {
  type = object(
    {
      aws_account_id         = string
      vpc_id                 = string
      route_table_cidr_block = string
    }
  )
}

variable "aws_endpoint_settings" {
  type = object(
    {
      region            = string
      vpc_id            = string
      subnet_id         = string
      security_group_id = string
    }
  )
}

variable "project" {
  type = object(
    {
      name   = string
      org_id = string
    }
  )
}

variable "network_container" {
  type = object(
    {
      atlas_cidr_block = string
      region           = string
    }
  )
}

variable "dbuser" {
  type = object(
    {
      name     = string
      password = string
      auth_database_name = string
      role_name = string
      database_name = string
      scope_name = string
      scope_type = string
    }
  )
}

variable "atlas_clusters" {
  type = map(object({
    project_id                  = string
    mongo_db_major_version      = string
    provider_name               = string
    region_name                 = string
    provider_instance_size_name = string
    disk_size_gb                = number
    cloud_backup                = bool
  }))
}

variable "dbusers_for_cluster" {
 type = map(object({
      username = string
      password = string
      auth_database_name = string
      project_id = string
      roles = list(object({
         role_name = string
         database_name = string
      }))
      scopes = list(object({
         name = string
         type = string
      }))
  }))
}

variable "snapshot" {
  type = object(
    {
      description       = string
      retention_in_days = number
      project_id        = string
      cluster_name      = string
      enable_snapshot   = bool
    }
  )
}

variable "restore_job" {
  type = object(
    {
      project_id   = string
      cluster_name = string
      snapshot_id  = string
      delivery_type_config = object(
        {
          automated           = bool
          target_cluster_name = string
          target_project_id   = string
        }
      )
      enable_restore = bool
    }
  )
}

variable "kms_key" {
  type = object(
    {
      atlas_region        = string
      customer_master_key = string
    }
  )
}
