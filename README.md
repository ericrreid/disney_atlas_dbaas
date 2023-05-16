# Example code snippets to support Disney's DBaaS effort
/terraform_templates: Terraform templates, making use of MongoDB Atlas Provider to:
  - Create Project resource, given existing Organization
  - Create multiple Clusters, given Project (via modules)
  - In support of Network Functions, Create Network Container (AWS)
  - Create VPC Peering connection
  - Create PrivateLink connection
  - Create ad hoc backup snapshot on Cluster  (note: Cluster will not have data)
  - Restore that snapshot to another Cluster (Note: overwrites data)
  - Use AWS KMS keys to encrypt Cluster data-at-rest 
  - Add DB users to Cluster (using DB User Scope)

/bash_scripts: Bash shell scripts, making use of Atlas Admin API to:
  - Get Atlas Events
  - Get mongod logs from Atlas Clusters
  - Get metrics from Atlas Clusters
  - Get metrics from Atlas Clusters in multiple Orgs

Tested with:
  - Bash v5.1 on MacOS and Linux
  - MongoDB Atlas Terraform 1.8.x
  - AWS Terraform Provider v4.48.x

Note: API Key must already exist AND have an API Access List with the desired IP Address or CIDR
Note: Assumes Atlas on AWS
Note: Specific values for your environment must be used (bash_scripts/common.sh, terraform_templates/versions.tf)

Author: eric.reid@mongodb.com
Repo: https://github.com/ericrreid/disney_atlas_dbaas

Note: all code is provided with the understanding that it is:
  - Not production-ready
  - Not fully tested in customer target environments
  - Not supported by MongoDB, Inc. in any fashion
