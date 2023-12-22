#!/bin/bash

# Usage information
usage() {
    echo "Usage: $0 [options]"
    echo "  -h, --help                      Display this help and exit"
    echo "  -full, --full-install           Install all components (Minikube, Kubectl, Docker)"
    echo "  -helm, --install-helm           Install Helm"
    echo "  -argocd, --install-argocd       Install ArgoCD"
    echo "  -start, --start-cluster         Start cluster"
}

# Check for required tools
check_required_tools() {
    for tool in curl wget sudo; do
        if ! command -v $tool &> /dev/null; then
            echo "Error: $tool is required but not installed." >&2
            exit 1
        fi
    done
}

# Error handling
execute_command() {
    "$@"
    if [ $? -ne 0 ]; then
        echo "Error executing: $1" >&2
        exit 1
    fi
}

# Install Minikube
install_minikube() {
    echo "############################"
    echo "Install Minikube"
    echo "############################"
    execute_command sudo apt update
    execute_command sudo apt-get install -y curl apt-transport-https ca-certificates curl gnupg
    execute_command wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    execute_command sudo cp minikube-linux-amd64 /usr/local/bin/minikube
    execute_command sudo chmod 755 /usr/local/bin/minikube
    execute_command minikube version
}

# Install Minikube
install_kubectl() {
    echo "############################"
    echo "Install Kubectl"
    echo "############################"
    execute_command curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
    execute_command sudo chmod +x ./kubectl
    execute_command sudo mv ./kubectl /usr/local/bin/kubectl
    execute_command kubectl version -o json

    echo "############################"
    echo "Update Kubectl Autocompletion"
    echo "############################"
    execute_command sudo apt-get install bash-completion -y
    execute_command kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
    execute_command echo 'alias k=kubectl' >>~/.bashrc
    execute_command echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
    execute_command source .bashrc
}

# Install Helm
install_helm() {
    echo "############################"
    echo "Install Helm"
    echo "############################"
    execute_command curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    execute_command sudo chmod 700 get_helm.sh
    execute_command ./get_helm.sh
}

# Install Docker
install_docker() {
    echo "############################"
    echo "Install Docker"
    echo "############################"
    execute_command sudo install -m 0755 -d /etc/apt/keyrings
    execute_command curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    execute_command sudo chmod a+r /etc/apt/keyrings/docker.gpg
    execute_command sudo apt-get update
    execute_command sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    execute_command sudo usermod -aG docker $USER
    execute_command newgrp docker
}

# Install Docker
update_system() {
    echo "############################"
    echo "Update system & network"
    echo "############################"
    execute_command sudo sed -i '/^#net\.ipv4\.ip_forward=0/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
    execute_command sudo sysctl -p
    execute_command sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
}

# Install ArgoCD
install_argocd() {
    echo "############################"
    echo "Install ArgoCD"
    echo "############################"
    execute_command kubectl create namespace argocd
    execute_command kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    execute_command k get secrets -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    execute_command kubectl port-forward -n argocd service/argocd-server 8081:80 --address 0.0.0.0 &
}

# Main script execution
check_required_tools

while :; do
    case $1 in
        -h|--help)
            usage
            exit
            ;;
        -full|--full-install)
            install_minikube
            install_kubectl
            install_docker
            update_system
            ;;
        -helm|--install-helm)
            install_helm
            ;;
        -argocd|--install-argocd)
            install_argocd
            ;;
        -start|--start-cluster)
            echo "############################"
            echo "Start cluster minikube"
            echo "############################"
            minikube start
            minikube tunnel
            echo "Cluster started"
            ;;
        *)
            break
    esac
    shift
    echo "Installation process completed."
done


