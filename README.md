All credit for this 'fork' to [ibm-blockchain](https://ibm-blockchain.github.io) specifically IBM's Helm Chart [ibm-blockchain-network](https://github.com/IBM-Blockchain/ibm-container-service/tree/master/helm-charts/ibm-blockchain-network)

### Description ###
Minor tweaks to IBM's Helm Chart to deploy to Kubernetes Engine on Google Cloud Platform (GCP).

(Hyperledger) Fabric is the foundation of IBM Blockchain Service.

Medium Story explaining "[Fabric on Google Cloud Platform](https://medium.com/google-cloud/fabric-on-google-cloud-platform-97525323457c)"

### Installation ###

1. Create [Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) cluster
1. Create NFS Service (see below)
1. Install [Helm](https://www.helm.sh/)
1. Install Tiller (see below)
1. Clone and install Chart (see below)

#### Deploy NFS ####

The Chart shares configuration data in a volume across multiple Pods and requires read-write many. This (read-write many) is not possible with Google's foundational Persistent Disk (PD) but it is possible by running an NFS Service on Kubernetes atop PD:

Credit to [Amine Jallouli](https://github.com/mappedinn) for [kubernetes-nfs-volume-on-gke](https://github.com/mappedinn/kubernetes-nfs-volume-on-gke):

If you'd prefer to use HDD rather than SSD, you need not apply this file to your cluster. If you would like to use SSD, you need to apply this file:

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
#reclaimPolicy: Retain
```

Create and apply this file to a Kubernetes cluster to create a PersistentVolumeClaim, an NFS Deployment and a NFS Service. If you would prefer to use HDD rather than SSD change `storageClassName` here to be `default` rather than `ssd`. If you would prefer to use SSD, please ensure you've applied the previous file to your cluster before you apply this file:

```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs
spec:
  storageClassName: ssd
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
...
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nfs
spec:
  replicas: 1
  selector:
    matchLabels:
      role: nfs
  template:
    metadata:
      labels:
        role: nfs
    spec:
      containers:
      - name: nfs
        image: gcr.io/google_containers/volume-nfs:0.8
        ports:
          - name: nfs
            containerPort: 2049
          - name: mountd
            containerPort: 20048
          - name: rpcbind
            containerPort: 111
        securityContext:
          privileged: true
        volumeMounts:
          - mountPath: /exports
            name: nfs
      volumes:
      - name: nfs
        persistentVolumeClaim:
          claimName: nfs
          readOnly: false
...
---
apiVersion: v1
kind: Service
metadata:
  name: nfs
spec:
  ports:
    - name: nfs
      port: 2049
    - name: mountd
      port: 20048
    - name: rpcbind
      port: 111
  selector:
    role: nfs
...
```

#### Install Tiller ####

If -- as is likely (encouraged) -- you're using an RBAC-based Kubernetes Engine cluster, this is a good way to install Helm's Tiller into the cluster after you've created both the Kubernets Engine cluster and installed Helm:

```
kubectl create serviceaccount tiller \
--namespace=kube-system

kubectl create clusterrolebinding tiller \
--clusterrole cluster-admin \
--serviceaccount=kube-system:tiller

helm init --service-account=tille
```

#### Clone & Install Helm Chart ####

You're now ready to install the Helm chart.

Clone it if not already, dry-run it to ensure it looks correct and then install it:

```
git clone https://github.com/DazWilkin/ibm-blockchain-network.git
helm install --debug --dry-run ibm-blockchain-network
helm install ibm-blockchain-network
```

The last command will return something similar to:
```
NAME:   funky-dragonfly
LAST DEPLOYED: Tue Jun  5 07:16:41 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Pod(related)
NAME                                                             READY  STATUS             RESTARTS  AGE
funky-dragonfly-ibm-blockchain-network-ca-f68c596fc-zg2mw        0/1    ContainerCreating  0         0s
ibm-blockchain-network-debug-nfs-654fd6f4d4-ddwvt                0/1    ContainerCreating  0         0s
funky-dragonfly-ibm-blockchain-network-orderer-787984744b-hm8lv  0/1    ContainerCreating  0         0s
funky-dragonfly-ibm-blockchain-network-org1peer1-775fcd5d49j8k5  0/1    ContainerCreating  0         0s
funky-dragonfly-ibm-blockchain-network-org2peer1-98888c8b6kgpkc  0/1    ContainerCreating  0         0s

==> v1/PersistentVolume
NAME                       CAPACITY  ACCESS MODES  RECLAIM POLICY  STATUS  CLAIM                              STORAGECLASS  REASON  AGE
ibm-blockchain-shared-pvc  1Gi       RWX           Retain          Bound   default/ibm-blockchain-shared-pvc  0s

==> v1/PersistentVolumeClaim
NAME                       STATUS  VOLUME                     CAPACITY  ACCESS MODES  STORAGECLASS  AGE
ibm-blockchain-shared-pvc  Bound   ibm-blockchain-shared-pvc  1Gi       RWX           0s

==> v1/Service
NAME                              TYPE      CLUSTER-IP     EXTERNAL-IP  PORT(S)                        AGE
ibm-blockchain-network-ca         NodePort  10.39.248.78   <none>       7054:30000/TCP                 0s
ibm-blockchain-network-orderer    NodePort  10.39.242.214  <none>       31010:31010/TCP                0s
ibm-blockchain-network-org1peer1  NodePort  10.39.250.198  <none>       5010:30110/TCP,5011:30111/TCP  0s
ibm-blockchain-network-org2peer1  NodePort  10.39.242.138  <none>       5010:30210/TCP,5011:30211/TCP  0s

==> v1/Pod
NAME                                          READY  STATUS             RESTARTS  AGE
funky-dragonfly-ibm-blockchain-network-utils  0/3    ContainerCreating  0         0s

==> v1beta1/Deployment
NAME                                              DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
funky-dragonfly-ibm-blockchain-network-ca         1        1        1           0          0s
ibm-blockchain-network-debug-nfs                  1        1        1           0          0s
funky-dragonfly-ibm-blockchain-network-orderer    1        1        1           0          0s
funky-dragonfly-ibm-blockchain-network-org1peer1  1        1        1           0          0s
funky-dragonfly-ibm-blockchain-network-org2peer1  1        1        1           0          0s


NOTES:
1. Get the application URL by running these commands:
   export POD_NAME=$(kubectl get pods --namespace default -l "app=ibm-blockchain-network,release=funky-dragonfly" -o jsonpath="{.items[0].metadata.name}")
   echo "Visit http://127.0.0.1:8080 to use your application"
   kubectl port-forward $POD_NAME 8080:80

2. Next, create a channel and have your peers join by running these commands:
   helm install stable/ibm-blockchain-channel
```

### Maintenance & Teardown ###

Enumerate deployed Charts:
```
helm list
```

Delete deployed Charts:
`helm list` will include the names of the charts that you may reference to delete charts:
```
helm delete [[NAME]]
```

You may delete the NFS Service in Kubernetes by `delete`-ing the files that you `apply`-ied earlier, perhaps (!):
```
kubectl delete --filename=nfs-deployment-service.yaml
kubectl delete --filename=ssd.yaml
```
