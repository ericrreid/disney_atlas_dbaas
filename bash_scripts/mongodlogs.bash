#! /bin/bash

source ./common.bash

# Given: pointer to S3 Bucket
# Given: array of Org IDs
# Given: array of Atlas API Keys

# Note: AWS CLI, grep, curl, jq and sed must be installed and executable
# Note: Will not work for Paused Clusters
# Note: Only works for Replica Sets and mongod logs at present
# Note: Cannot get logs from M0, M2 or M5 Cluster Tiers
# Note: Compressed logfiles cannot easily be parsed to obtain last 15 min data
# Note: Must be able to create tempfiles in current directory

# For each Org
numOrgs=${#ORGS[@]}
for (( org=0; org<${numOrgs}; org++ ));
do
  echo "Org "$org": "${ORGS[${org}]}

  curlCmd="$CURL --user "${API_KEYS[${org}]}" --digest"

# For each Project in Org
  projects=`${curlCmd} --request GET "${API_ENDPOINT}/orgs/${ORGS[${org}]}/groups/?pretty=true" \
            | jq '.results[].id' | sed -e 's/"//g'`
    for proj in ${projects}; 
    do
      echo "   Project: "${proj}

#   For each Cluster (for debugging only)
      clusters=`${curlCmd} --request GET "${API_ENDPOINT}/groups/${proj}/clusters?pretty=true" \
                | jq '.results[].id' | sed -e 's/"//g'`
      for clust in ${clusters};
      do 
        echo "      Cluster: "${clust}
      done

#   For each host in the Project
      hosts=`${curlCmd} --request GET "${API_ENDPOINT}/groups/${proj}/processes?pretty=true" \
             | jq '.results[].hostname' | sed -e 's/"//g'`
      for host in ${hosts}; 
      do

#     Get logfile
        datestring=`date "+%s"`
        localfile="./mongodb.log.${host}.${datestring}.log.gz"
        status=`${curlCmd} -o ${localfile} --request GET "${API_ENDPOINT}/groups/${proj}/clusters/${host}/logs/mongodb.gz"`
#       If this error is thrown, the file won't compress, and is searchable for this condition
        if [ ! -z "`grep TENANT_CLUSTER_LOGS_FOR_HOST_NOT_SUPPORTED ${localfile}`" ];
        then
          echo "Warning: "${host}" is part of an Atlas Cluster which does not allow download of logs"
          rm ${localfile}
        else
#       Place logfile in existing S3 Bucket
          ${AWSCLI} s3 cp ${localfile} ${S3_BUCKET_1}
        fi 
      done
    done
done

