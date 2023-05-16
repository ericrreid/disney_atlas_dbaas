#! /bin/bash

source ./common.bash

# Note: works only for Replica Sets and mongod processes at present

# Given: Atlas Project
# Given: Atlas Cluster

# Note: We retrieved the URI for the Cluster; each of the constituent nodes can then
# be used to get metrics (measurements), although the hostnames are aliases 
# to the actual underlying Atlas host

# Metrics currently available via the API: see https://www.mongodb.com/docs/atlas/reference/api-resources-spec/#tag/Monitoring-and-Logs/operation/getHostMeasurements

periodGranularity="&period=PT1H&granularity=PT5M"
base="${API_ENDPOINT}/groups/${METRICS_PROJECT}/clusters/${METRICS_CLUSTER}"
parameters="pretty=true"

uri=`$CURL --user "${METRICS_API_KEY}" --digest \
  --request GET "${base}?{parameters}" \
  | jq '.mongoURI'`
processes=`echo ${uri} | sed -e 's/"//g' | awk -F/ '{print $3}' | sed 's/,/ /g'`

# We can use SYSTEM_NORMALIZED_CPU_USER as a reasonable approximation of total CPU%,
# But note that this will usually be greater on the (at that time) Primary

# Limitation: At this writing, there's no way to programmatically assertain
# Current Primary for Replica Set (nor historical Primary)

for proc in ${processes}; 
do
  echo "Process: "${proc}
  base="${API_ENDPOINT}/groups/${METRICS_PROJECT}/processes/${proc}/measurements"

  parameters="m=MAX_SYSTEM_MEMORY_USED"${periodGranularity}"&pretty=true"
  memoryUsedResponse=`$CURL --user "${METRICS_API_KEY}" --digest \
    --request GET "${base}?${parameters}" \
    | jq '.measurements[].dataPoints'`
  timestamps=`echo ${memoryUsedResponse} | jq '.[].timestamp' | sed -e 's/"/ /g'`
  memUsed=`echo ${memoryUsedResponse} | jq '.[].value' | sed -e 's/"/ /g'`

  parameters="m=MAX_SYSTEM_MEMORY_FREE"${periodGranularity}"&pretty=true"
  memoryFreeResponse=`$CURL --user "${METRICS_API_KEY}" --digest \
    --request GET "${base}?${parameters}" \
    | jq '.measurements[].dataPoints'`
  memFree=`echo ${memoryFreeResponse} | jq '.[].value' | sed -e 's/"/ /g'`

  parameters="m=MAX_PROCESS_NORMALIZED_CPU_USER"${periodGranularity}"&pretty=true"
  cpuPercentResponse=`$CURL --user "${METRICS_API_KEY}" --digest \
    --request GET "${base}?${parameters}" \
    | jq '.measurements[].dataPoints'`
  cpuUserPercent=`echo ${cpuPercentResponse} | jq '.[].value' | sed -e 's/"/ /g'`

  ts=($timestamps)
  mu=($memUsed)
  mf=($memFree)
  cpu=($cpuUserPercent)

  numReadings=`echo ${timestamps} | wc -w`
  for (( reading=0; reading<${numReadings}; reading++ )); do
    echo ${ts[$reading]}": Max Normalized CPU: "`echo "scale=0; ${cpu[$reading]} / 1" | bc`"% / Max System Mem: "`echo "scale=0; 100 * ${mu[$reading]} / ( ${mu[$reading]} + ${mf[$reading]} )" | bc`"%"
  done
  echo ""
done
