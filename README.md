# k8s-check-deprecated-apis
Script to generate a yaml file for each object in a namespace and then use pluto utility to check for depricated APIs.

## Usage
```
# Create a dir for your cluster
mkdir cluster_a1
cd cluster_a1

# Download the script
curl https://raw.githubusercontent.com/sturrent/k8s-check-deprecated-apis/master/check_deprecated_apis.sh -o check_deprecated_apis.sh
chmod u+x check_deprecated_apis.sh

# Run the script as follow and it will use the current active context on your kubeconfig
bash check_deprecated_apis.sh

# Output will show the script progress and any existing failures
```

If no namespace is provided, the script will use the default one.
The following is an example of the execution against kube-system namespace:
```
:~/cluster_a1$ curl https://raw.githubusercontent.com/sturrent/k8s-check-deprecated-apis/master/check_deprecated_apis.sh -o check_deprecated_apis.sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3566  100  3566    0     0    602      0  0:00:05  0:00:05 --:--:--  1048
:~/cluster_a1$ chmod u+x check_deprecated_apis.sh
:~/cluster_a1$ bash check-deprecated-api.sh
+++Downloading pluto binary...
/home/sturrent/k8s-check-deprecated-apis/pluto/plut 100%[===================================================================================================================>]   8.34M  6.70MB/s    in 1.2s
...done

+++Using the following context to connect to cluster:

--------------------------------------------------------------------------
NAME      CLUSTER   AUTHINFO
aks-net1  aks-net1  clusterUser_aks-net1-rg_aks-net1
--------------------------------------------------------------------------

+++Collecting data in the following namespaces:

default
ingress-2
ingress-basic
kube-node-lease
kube-public
kube-system
wp1

----------------------Results-------------------------

NAME                NAMESPACE   KIND      VERSION              REPLACEMENT            DEPRECATED   DEPRECATED IN   REMOVED   REMOVED IN
ingress-2-master    ingress-2   Ingress   extensions/v1beta1   networking.k8s.io/v1   true         v1.14.0         false     v1.22.0
hello-world-one     wp1         Ingress   extensions/v1beta1   networking.k8s.io/v1   true         v1.14.0         false     v1.22.0
wordpress-ingress   wp1         Ingress   extensions/v1beta1   networking.k8s.io/v1   true         v1.14.0         false     v1.22.0


----------------------Done-------------------------
```

## Credits
To [pluto](https://github.com/FairwindsOps/pluto) utility created by Fairwinds.
