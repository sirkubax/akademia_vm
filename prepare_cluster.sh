#!/bin/bash
#https://github.com/seenu433/arc-k8s/blob/main/workshop.mdA

whoami
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update && sudo apt-get install -y docker-ce=5:19.03.14* docker-ce-cli=5:19.03.14* containerd.io=1.2.10*

echo "Configuring Docker..."

sudo cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "Installing Kubernetes components..."

sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add 
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update && sudo apt-get install -y kubelet=1.19.14* kubeadm=1.19.14* kubectl=1.19.14*
sudo apt-mark hold kubelet kubeadm kubectl


#kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-cert-extra-sans IP 
#kubectl taint nodes --all node-role.kubernetes.io/master-

#kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v3.10/manifests/calico.yaml
#kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
