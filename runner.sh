#!/bin/bash

# script name: runner.sh
# v0.2.1 20210715
# Script to execute the check_deprecated_api.sh script

# VARs
CONFIG_FILE="/kubeconfig"
APISERVER=https://kubernetes.default.svc
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
TOKEN=$(cat ${SERVICEACCOUNT}/token)
SA_NAME=check-deprecated 

function download_kubectl () {
    echo -e "+++ Downloading kubectl binary..."
    if curl --connect-timeout 3 -o /usr/bin/kubectl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    then
        chmod u+x /usr/bin/kubectl
    else
        echo -e "Error: download failed..."
        exit 1
    fi
}

function set_kubectl () {
    kubectl --kubeconfig=$CONFIG_FILE config set-cluster kubernetes \
        --embed-certs=true \
        --server=$APISERVER \
        --certificate-authority=${SERVICEACCOUNT}/ca.crt
    kubectl --kubeconfig=$CONFIG_FILE config set-credentials $SA_NAME --token=$TOKEN
}

function run_api_check () {
    bash /check_deprecated_apis.sh
}


# MAIN

download_kubectl
set_kubectl
run_api_check

exit 0
