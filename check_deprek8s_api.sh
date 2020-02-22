#!/bin/bash

# v0.0.7
# Script to generate a yaml file for each object in a namespace
# and then use confest binary to test against deprek8.rego policies


# vars
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
SCRIPT_NAME="$(echo $0 | sed 's|\.\/||g')"
OUTPUT_FILE=${SCRIPT_PATH}/output.txt
OBJECTS_LIST="pods,pvc,configmap,serviceaccount,ingress,service,deployment,statefulset,hpa,job,cronjob"
SPIN='-\|/'

# Argument validation
if [ "$#" -gt 1 ]
then
    echo -e "only the namespace is expected as argument...\n"
    echo -e "Usage: bash ${SCRIPT_PATH}/${SCRIPT_NAME} <NAMESPACE>\n"
	exit 1
elif [ -z "$1" ]
then
    NAMESPACE="default"
else
    NAMESPACE="$1"
fi

# check if kubectl is installed
if ! [ -x "$(command -v kubectl)" ]
then
  echo -e "Error: kubectl is not installed.\n"
  exit 1
fi

# Funtion definition
function get_k8s_objects () {
    kubectl -n $NAMESPACE get -o=name $OBJECTS_LIST
}

# get_yaml_from_objects
function get_yaml_from_objects () {
    i=0
    for OBJECT in $K8S_OBJECTS
    do 
        mkdir -p $(dirname ${NAMESPACE}_${OBJECT})
        OBJECT_NAME=$(echo $OBJECT | cut -d "/" -f1)
        FILE_NAME=$(echo $OBJECT | cut -d "/" -f2)
        $(kubectl -n $NAMESPACE get -o=yaml $OBJECT > ${NAMESPACE}_$OBJECT_NAME/${FILE_NAME}.yaml)&
        i=$(( (i+1) %4 ))
        printf "\r${SPIN:$i:1}"
        sleep 0.2
    done
    wait
}

# main
echo -e "Getting cluster objects from $NAMESPACE namespace..."
K8S_OBJECTS=$(get_k8s_objects)
echo -e "...done\n"
echo -e "Getting yaml for each object in $NAMESPACE namespace..."
get_yaml_from_objects
echo -e "\n...done\n"

for YAML in $(find ${SCRIPT_PATH} -type f -name "*.yaml")
do conftest test -p ${SCRIPT_PATH}/deprek8.rego $YAML
done > $OUTPUT_FILE

if $(grep -q FAIL $OUTPUT_FILE)
then
    echo -e "The fallowing failures have been found (full output avaliable in ${OUTPUT_FILE}):\n"
    grep FAIL $OUTPUT_FILE
else
    echo -e "No issues found, full result avaliable in file $OUTPUT_FILE"
fi

exit 0