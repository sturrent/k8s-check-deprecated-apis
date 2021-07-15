#!/bin/bash

# script name: check_deprecated_apis.sh
# v0.2.1 20210715
# Script to generate a yaml file for each object in a namespace
# and then use pluto binary to test for API deprecation.

# vars
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
SCRIPT_NAME="$(echo $0 | sed 's|\.\/||g')"
OUTPUT_DIR=${SCRIPT_PATH}/out_dir
PLUTO_DIR=${SCRIPT_PATH}/pluto
PLUTO_BIN=${PLUTO_DIR}/pluto
PLUTO_TAR="pluto_4.2.0_linux_amd64.tar.gz"
NAMESPACES_LIST=""
OBJECTS_LIST="pods,podsecuritypolicy,statefulset,pvc,configmap,serviceaccount,ingress,service,deployment,replicaset,statefulset,hpa,job,cronjob,CustomResourceDefinition,APIService,CertificateSigningRequest,Lease"
SPIN='-\|/'

# Funtion definition

function check_kubectl_exist () {
    if ! [ -x "$(command -v kubectl)" ]
    then
        echo -e "Error: kubectl is not installed.\n"
        exit 1
    fi
}

function get_current_context () {
    echo -e "+++ Using the following context to connect to cluster: \n"
    echo "--------------------------------------------------------------------------"
    kubectl config get-contexts | grep "^CURRENT\|^*" | awk '{print $2" "$3" "$4}' | column -t
    echo "--------------------------------------------------------------------------"
}

function download_pluto () {
    echo -e "+++ Downloading pluto binary..."
    mkdir -p $PLUTO_DIR 2> /dev/null
    if wget -q --timeout=240 --show-progress https://github.com/FairwindsOps/pluto/releases/download/v4.2.0/pluto_4.2.0_linux_amd64.tar.gz -O ${PLUTO_DIR}/${PLUTO_TAR}
    then
        tar xzf ${PLUTO_DIR}/${PLUTO_TAR} -C $PLUTO_DIR
    else
        echo -e "Error: download failed..."
        rm -rf $PLUTO_DIR 2> /dev/null
        exit 4
    fi
    echo -e "...done\n"
}

function get_all_namespaces () {
    NAMESPACES_LIST=$(kubectl get ns | grep -v ^NAME | awk '{print $1}' )
    if [ -z "$NAMESPACES_LIST" ]
    then
        echo -e "Error: cluster not reachable or not able to get namespaces list..."
        exit 1
    fi 
}

function get_k8s_objects () {
    NS=$1
    kubectl -n $NS get -o=name $OBJECTS_LIST 2>/dev/null
}

function get_yaml_from_objects () {
    NS=$1
    mkdir -p $OUTPUT_DIR 2> /dev/null
    i=0
    for OBJECT in $K8S_OBJECTS
    do 
        mkdir -p $(dirname ${OUTPUT_DIR}/${NS}_${OBJECT})
        OBJECT_NAME=$(echo $OBJECT | cut -d "/" -f1)
        FILE_NAME=$(echo $OBJECT | cut -d "/" -f2)
        $(kubectl -n $NS get -o=yaml $OBJECT > ${OUTPUT_DIR}/${NS}_$OBJECT_NAME/${FILE_NAME}.yaml 2> /dev/null)&
        i=$(( (i+1) %4 ))
        printf "\r${SPIN:$i:1}"
        sleep 0.5
    done
    printf "\r"
    wait
}

function get_yamls_from_namespaces () {
    echo -e "\n+++ Collecting data in the following namespaces:\n"
    for NS in $NAMESPACES_LIST
    do
        # collect cluster yamls form the requested namespace
        echo "$NS"
        K8S_OBJECTS=$(get_k8s_objects "$NS")
        get_yaml_from_objects "$NS"
    done
    printf "\r "
}

function test_yaml_against_policy () {
    $PLUTO_BIN detect-files -d $OUTPUT_DIR -o wide
}

## main

# check kubectl binary exists
check_kubectl_exist

# check if pluto is in place
if [ ! -f "$PLUTO_BIN" ]
then
    rm -rf $PLUTO_DIR 2> /dev/null
    download_pluto
fi

# show the currently active context
get_current_context

# get list of namespaces in cluster
get_all_namespaces

# collect cluster yamls form all namespaces
get_yamls_from_namespaces

# check yamls with policy
echo -e "\n----------------------Results-------------------------\n"
test_yaml_against_policy
echo -e "\n----------------------Done----------------------------\n"

exit 0