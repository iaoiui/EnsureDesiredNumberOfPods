
############################# CONST and FUNCTION ########################################
# max failed count 
MAX_FAILED_THRESHOLD=0
# fetch interval(minutes)
FECTH_INTERBVAL=1

# failed count is stored in this directory
TMP_DIR=/tmp/monitoring

TMP_FILE=/tmp/result

# Obtain Teams Incoming Webhook endpoint
TEAMS_ENDPOINT=<YOUR_ENDPOINT>


# returns Deviation Number
# $line: namespace pod_name replicas desired_replicas
have_problem () {
  echo  $line | awk '{print $3-$4}'
}
# inclements failed count
# $1 namespace
# $2 pod_name
inclement_failed_count (){
  # TODO how to implement
  touch $TMP_DIR/$1_$2
}

# check whether failed count reach MAX_FAILED_THRESHOLD
# $1 namespace
# $2 pod_name
reach_failed_count_threshold () {
  # TODO How to check ??
  filename=$TMP_DIR/$1_$2

  if [ -e $filename  ];then
    echo true
  else
    echo false
  fi

  #failed_count_of_pod="???"
  
  #if [ failed_count_of_pod -gte MAX_FAILED_THRESHOLD ]; then
  #  echo "something wrong about $pod_name"
  #fi
}

# alert to operator
# $1 namespace
# $2 pod_name
alert_to_operator (){
  # TODO alert to Teams
  
curl $TEAMS_ENDPOINT -H 'Content-type: application/json' -d @-  << EOF 
  {"text": "${namespace} namespace:   ${pod_name} is something wrong" }  
EOF
}

reset_failed_count (){
  rm -rf $TMP_DIR
}


############################# MAIN ########################################
reset_failed_count
mkdir -p $TMP_DIR

oc get deploy,sts --all-namespaces -ojsonpath="{ range .items[*]}{['.metadata.namespace','.metadata.name', '.status.replicas', '.status.readyReplicas']}{'\n'}" > $TMP_FILE
# TODO if we want to set interval, another reset way should be implemented

# main func
# Check current number of replicas and update failed count.
cat $TMP_FILE  | while read line
do
  #echo $line
  debiation_num=`have_problem $line`
  #echo $debiation_num
  pod_name=`echo $line | awk '{print $2}'`
  namespace=`echo $line | awk '{print $1}'`
  if [ ! $debiation_num = 0 ]; then
    inclement_failed_count $namespace $pod_name
  fi 

done


# if failed count reaches MAX_FAILED_THRESHOLD, alert the issue to operators
# this implementation depends on how to store the failed count.
cat $TMP_FILE  | while read line
do
  pod_name="`echo $line | awk '{print $2}'`"
  namespace="`echo $line | awk '{print $1}'`"
  reach_threshold="`reach_failed_count_threshold $namespace $pod_name`"
  
  # TODO ugokanai
  if [ $reach_threshold = true ]; then
    alert_to_operator $namespace $pod_name
  fi
done
