#! /bin/bash

# Install minikube
echo "############################"
echo "Install Minikube"
echo "############################"
sudo apt update
sudo apt-get install -y curl apt-transport-https ca-certificates curl gnupg
wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo cp minikube-linux-amd64 /usr/local/bin/minikube
sudo chmod 755 /usr/local/bin/minikube
minikube version

# Install Helm
echo "############################"
echo "Install Helm"
echo "############################"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
./get_helm.sh

# Install kubectl
echo "############################"
echo "Install Kubectl"
echo "############################"
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
sudo chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version -o json

echo "############################"
echo "Update Kubectl Autocompletion"
echo "############################"
sudo apt-get install bash-completion -y
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
source .bashrc

# Install Docker
echo "############################"
echo "Install Docker"
echo "############################"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "############################"
echo "Update system & network"
echo "############################"
sudo usermod -aG docker admin 
groupadd docker
sudo sed -i '/^#net\.ipv4\.ip_forward=0/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
sudo sysctl -p
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "############################"
echo "Install Start Minikube"
echo "############################"
minikube start
minikube tunnel &

echo "############################"
echo "Install Create ArgoCD"
echo "############################"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

k get secrets -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

kubectl port-forward -n argocd service/argocd-server 8081:80 --address 0.0.0.0 &

