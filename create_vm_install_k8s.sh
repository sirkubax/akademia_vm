#!/bin/bash
set -v

#------------------------------------------
MySubscription=149007b7-60ed-49ae-983a-b038a901db43

groupName="Example-K8S"
resourceGroupName=$groupName
resourceLocation="westeurope" # "eastus" or "westeurope"
vnetName=k8s-vnet
subnetName=k8s-subnet
clusterName=k8s-v1

kubeConfFile=/etc/kubernetes/admin.conf
#kubeConfFile=/etc/rancher/k3s/k3s.yaml

nodeName=k8s-node-1
pubIpName=k8s-node-1

az account set --subscription $MySubscription

az group create --name $resourceGroupName --location $resourceLocation

az network vnet create --name $vnetName --resource-group $resourceGroupName --location $resourceLocation --address-prefixes 172.10.0.0/16 --subnet-name $subnetName --subnet-prefixes 172.10.1.0/24

az vm create --name $nodeName --resource-group $resourceGroupName --location $resourceLocation --image UbuntuLTS --admin-user ubuntu --generate-ssh-keys --size Standard_DS2_v2 --data-disk-sizes-gb 10 --public-ip-address $pubIpName --public-ip-address-dns-name $pubIpName --subnet $subnetName --vnet-name $vnetName

staticIp=$(az network public-ip show --resource-group $resourceGroupName --name $pubIpName --output tsv --query ipAddress)
echo $staticIp
az network nsg rule list --nsg-name ${nodeName}NSG --resource-group $resourceGroupName
az network nsg rule create --nsg-name ${nodeName}NSG --resource-group $resourceGroupName --access Allow --destination-port-ranges 6443 --name port6443 --priority 1111
az network nsg rule create --nsg-name ${nodeName}NSG --resource-group $resourceGroupName --access Allow --destination-port-ranges 443 --name port443 --priority 2222
scp prepare_cluster.sh  ubuntu@$staticIp:prepare_cluster.sh
ssh $staticIp -l ubuntu  'sudo bash prepare_cluster.sh'
ssh $staticIp -l ubuntu  "sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-cert-extra-sans $staticIp"
ssh $staticIp -l ubuntu  "sudo kubectl taint nodes --all node-role.kubernetes.io/master-"
ssh $staticIp -l ubuntu  "sudo kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.10/manifests/calico.yaml"
ssh $staticIp -l ubuntu  "sudo kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml"
ssh $staticIp -l ubuntu  "sudo wget https://github.com/derailed/k9s/releases/download/v0.24.15/k9s_Linux_x86_64.tar.gz"
ssh $staticIp -l ubuntu  "sudo tar -xzvf k9s_Linux_x86_64.tar.gz"



