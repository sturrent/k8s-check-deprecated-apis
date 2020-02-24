# k8s-check-depricated-apis
Script to generate a yaml file for each object in a namespace and then use confest utility to test against deprek8.rego policies

## Usage
```
# Create a dir for your cluster
mkdir cluster_a1
cd cluster_a1

# Donwload the script
curl https://raw.githubusercontent.com/sturrent/k8s-check-depricated-apis/master/check_deprek8s_api.sh -o check_deprek8s_api.sh
chmod u+x check_deprek8s_api.sh

# Run the script providing the namespace you want to review
bash check_deprek8s_api.sh kube-system

# Output will show the script progress and if there are any failures (full output wil be saved in <NAMESPACE>_output.txt)
```

If no namespace is provided the script will use the default one.
Here is an example of the execution against kube-system namespace:
```
:~/cluster_a1$ curl https://raw.githubusercontent.com/sturrent/k8s-check-depricated-apis/master/check_deprek8s_api.sh -o check_deprek8s_api.sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3566  100  3566    0     0    602      0  0:00:05  0:00:05 --:--:--  1048
:~/cluster_a1$ chmod u+x check_deprek8s_api.sh
:~/cluster_a1$ bash check_deprek8s_api.sh kube-system
Downloading deprek8 policy...
/home/sturrent/cluster_a1/deprek8.rego 100%[=========================================================================>]   4.35K  --.-KB/s    in 0s
...done

Downloading conftest binary...
/home/sturrent/cluster_a1/conftest/con 100%[=========================================================================>]  10.47M  3.17MB/s    in 3.3s
...done

Getting cluster objects from kube-system namespace...
...done

Getting yaml for each object in kube-system namespace...
|
...done

The fallowing failures have been found for namespace kube-system (full output avaliable in /home/sturrent/cluster_a1/kube-system_output.txt):

FAIL - /home/sturrent/cluster_a1/out_dir/kube-system_deployment.extensions/calico-typha-horizontal-autoscaler.yaml - Deployment/calico-typha-horizontal-autoscaler: API extensions/v1beta1 for Deployment is no longer served by default, use apps/v1 instead.
FAIL - /home/sturrent/cluster_a1/out_dir/kube-system_deployment.extensions/calico-typha.yaml - Deployment/calico-typha: API extensions/v1beta1 for Deployment is no longer served by default, use apps/v1 instead.
FAIL - /home/sturrent/cluster_a1/out_dir/kube-system_deployment.extensions/coredns-autoscaler.yaml - Deployment/coredns-autoscaler: API extensions/v1beta1 for Deployment is no longer served by default, use apps/v1 instead.
FAIL - /home/sturrent/cluster_a1/out_dir/kube-system_deployment.extensions/coredns.yaml - Deployment/coredns: API extensions/v1beta1 for Deployment is no longer served by default, use apps/v1 instead.
FAIL - /home/sturrent/cluster_a1/out_dir/kube-system_deployment.extensions/kubernetes-dashboard.yaml - Deployment/kubernetes-dashboard: API extensions/v1beta1 for Deployment is no longer served by default, use apps/v1 instead.
FAIL - /home/sturrent/cluster_a1/out_dir/kube-system_deployment.extensions/metrics-server.yaml - Deployment/metrics-server: API extensions/v1beta1 for Deployment is no longer served by default, use apps/v1 instead.
FAIL - /home/sturrent/cluster_a1/out_dir/kube-system_deployment.extensions/tunnelfront.yaml - Deployment/tunnelfront: API extensions/v1beta1 for Deployment is no longer served by default, use apps/v1 instead.
:~/cluster_a1$
```

## Credits
This script was inspired by the article [Testing for Deprecated Kubernetes APIs](https://thepracticalsysadmin.com/testing-for-deprecated-kubernetes-apis/) by Josh Reichardt and it leverage the [conftest](https://github.com/instrumenta/conftest) utility as well as the Kubernetes depricated API policy [deprek8](https://github.com/naquada/deprek8)