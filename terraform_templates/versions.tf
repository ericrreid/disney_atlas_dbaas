terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "1.9.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.48.0"
    }
  }
}
