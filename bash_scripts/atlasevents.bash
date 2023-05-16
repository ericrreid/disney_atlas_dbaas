#! /bin/bash

source ./common.bash

# Given: two S3 Buckets
# Given: array of Org IDs
# Given: array of Atlas API Keys

# Note: AWS CLI, jq, curl and sed must be installed and executable
# Note: Returned events not yet parsed to obtain last 15 min of events
# Note: Must be able to create tempfiles in current directory

# For each Org
numOrgs=${#ORGS[@]}
for (( org=0; org<${numOrgs}; org++ ));
do
  echo "Org "$org": "${ORGS[${org}]}
  curlCmd="$CURL --user "${API_KEYS[${org}]}" --digest"

  datestring=`date "+%s"`
  orgfile="./atlas.orgevents.${org}.${datestring}.json"
  events=`${curlCmd} -o ${orgfile} --request GET "${API_ENDPOINT}/orgs/${ORGS[${org}]}/events?pretty=true" \
          | jq '.results[]' | sed -e 's/"//g'`

# Place Org events in existing S3 Bucket (last 15 minutes, if possible)
  ${AWSCLI} s3 cp ${orgfile} ${S3_BUCKET_1}
  ${AWSCLI} s3 cp ${orgfile} ${S3_BUCKET_2}

# For each Project in Org
  projects=`${curlCmd} --request GET "${API_ENDPOINT}/orgs/${ORGS[${org}]}/groups/?pretty=true" \
            | jq '.results[].id' | sed -e 's/"//g'`
  for proj in ${projects};
  do
    echo "   Project: "${proj}
    projfile="./atlas.project.events.${proj}.${datestring}.json"
    events=`${curlCmd} -o ${projfile} --request GET "${API_ENDPOINT}/groups/${proj}/events?pretty=true" \
            | jq '.results[]' | sed -e 's/"//g'`
#   Place Project events in existing S3 Bucket (last 15 minutes, if possible)
    ${AWSCLI} s3 cp ${projfile} ${S3_BUCKET_1}
    ${AWSCLI} s3 cp ${projfile} ${S3_BUCKET_2}
  done
done

