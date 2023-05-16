#! /bin/bash

# Common values to be used in these example scripts
# Replace all things starting with "XX" with your with your values

# Note: number of array elements in $API_KEYS must match that in $ORGS

# For testing multiple Orgs

API_KEYS=("XXPUBLIC:XXPRIVATE" "XXPUBLIC:XXPRIVATE") 
ORGS=("XXORG1" "XXORG2") 
S3_BUCKET_1="s3://XXBUCKET1"
S3_BUCKET_2="s3://XXBUCKET2"

# For returning metrics
METRICS_API_KEY="XXPUBLIC:XXPRIVATE"
METRICS_PROJECT="XXPROJECT"
METRICS_CLUSTER="XXCLUSTERNAME"
METRICS_S3_BUCKET="s3://XXBUCKET"

AWS_REGION="XXREGION"
export AWS_ACCESS_KEY_ID="XXKEY"
export AWS_SECRET_ACCESS_KEY="XXSECRETKEY"

# If required
export AWS_SESSION_TOKEN="XXTOKEN"

# Change if your path is different
AWSCLI="/usr/local/bin/aws --region $AWS_REGION"

CURL="/usr/bin/curl -s" # Silent
JQ=/usr/local/bin/jq
API_ENDPOINT="https://cloud.mongodb.com/api/atlas/v1.0"

