#!/bin/bash

# script name: check_deprek8s_api.sh
# v0.1.9 20200224
# Script to generate a yaml file for each object in a namespace
# and then use confest binary to test against deprek8.rego policies

# vars
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
SCRIPT_NAME="$(echo $0 | sed 's|\.\/||g')"
OUTPUT_DIR=${SCRIPT_PATH}/out_dir
DEPREK8_POLICY=${SCRIPT_PATH}/deprek8.rego
CONFTEST_DIR=${SCRIPT_PATH}/conftest
CONFTEST_BIN=${CONFTEST_DIR}/conftest
OBJECTS_LIST="pods,pvc,configmap,serviceaccount,ingress,service,deployment,replicaset,statefulset,hpa,job,cronjob"
SPIN='-\|/'

# Argument validation
if [ "$#" -gt 1 ]
then
    echo -e "Only one namespace is expected as argument...\n"
    echo -e "Usage: bash ${SCRIPT_PATH}/${SCRIPT_NAME} <NAMESPACE>\n"
	exit 1
elif [ -z "$1" ]
then
    NAMESPACE="default"
else
    NAMESPACE="$1"
fi
OUTPUT_FILE=${SCRIPT_PATH}/${NAMESPACE}_output.txt


# Funtion definition

function check_kubectl_exist () {
    if ! [ -x "$(command -v kubectl)" ]
    then
        echo -e "Error: kubectl is not installed.\n"
        exit 1
    fi
}

function check_namespace_exist () {
    if ! kubectl get ns $NAMESPACE > /dev/null 2>&1 
    then
        echo -e "Error: the namespace $NAMESPACE does not exist in the cluster...\n"
        exit 3
    fi
}

function download_conftest () {
    echo -e "Downloading conftest binary..."
    mkdir -p $CONFTEST_DIR 2> /dev/null
    if wget -q --timeout=240 --show-progress https://github.com/instrumenta/conftest/releases/download/v0.16.0/conftest_0.16.0_Linux_x86_64.tar.gz -O ${CONFTEST_DIR}/conftest_0.16.0_Linux_x86_64.tar.gz
    then
        tar xzf ${CONFTEST_DIR}/conftest_0.16.0_Linux_x86_64.tar.gz -C $CONFTEST_DIR
    else
        echo -e "Error: download failed..."
        rm -rf $CONFTEST_DIR 2> /dev/null
        exit 4
    fi
    echo -e "...done\n"
}

function download_deprek8 () {
    echo -e "Downloading deprek8 policy..."
    if wget -q --timeout=120 --show-progress https://raw.githubusercontent.com/naquada/deprek8/master/policy/deprek8.rego -O $DEPREK8_POLICY
    then
        echo -e "...done\n"
    else
        echo -e "Error: download failed..."
        rm -rf $DEPREK8_POLICY 2> /dev/null
        exit 5
    fi
}

function get_k8s_objects () {
    kubectl -n $NAMESPACE get -o=name $OBJECTS_LIST
}

function get_yaml_from_objects () {
    mkdir -p $OUTPUT_DIR 2> /dev/null
    i=0
    for OBJECT in $K8S_OBJECTS
    do 
        mkdir -p $(dirname ${OUTPUT_DIR}/${NAMESPACE}_${OBJECT})
        OBJECT_NAME=$(echo $OBJECT | cut -d "/" -f1)
        FILE_NAME=$(echo $OBJECT | cut -d "/" -f2)
        $(kubectl -n $NAMESPACE get -o=yaml $OBJECT > ${OUTPUT_DIR}/${NAMESPACE}_$OBJECT_NAME/${FILE_NAME}.yaml)&
        i=$(( (i+1) %4 ))
        printf "\r${SPIN:$i:1}"
        sleep 0.2
    done
    wait
}

function test_yaml_against_policy () {
    for YAML in $(find ${OUTPUT_DIR}/${NAMESPACE}_* -type f -name "*.yaml")
    do $CONFTEST_BIN test -p $DEPREK8_POLICY $YAML
    done > $OUTPUT_FILE
}

## main

# check kubectl binary exists
check_kubectl_exist

# check namespace exist
check_namespace_exist

# check if deprek8 policy is in place
if [ ! -f "$DEPREK8_POLICY" ]
then
    download_deprek8
fi

# check if conftest is in place
if [ ! -f "$CONFTEST_BIN" ]
then
    rm -rf $CONFTEST_DIR 2> /dev/null
    download_conftest
fi

# collect cluster yamls form the requested namespace
echo -e "Getting cluster objects from $NAMESPACE namespace..."
K8S_OBJECTS=$(get_k8s_objects)
echo -e "...done\n"
echo -e "Getting yaml for each object in $NAMESPACE namespace..."
get_yaml_from_objects
echo -e "\n...done\n"

# check yamls with policy
test_yaml_against_policy

if $(grep -q FAIL $OUTPUT_FILE)
then
    echo -e "The following failures have been found for namespace $NAMESPACE (full output avaliable in ${OUTPUT_FILE}):\n"
    grep FAIL $OUTPUT_FILE
else
    echo -e "No issues were found for namespace $NAMESPACE, full result avaliable in file $OUTPUT_FILE"
fi

exit 0