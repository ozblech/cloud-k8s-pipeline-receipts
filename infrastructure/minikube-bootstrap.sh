#!/bin/bash
exec > >(tee /var/log/minikube-bootstrap.log | logger -t user-data -s) 2>&1
set -eux

# Update and install dependencies
dnf update -y --allowerasing || echo "dnf update failed"
dnf install -y --allowerasing docker git curl wget conntrack || echo "package install failed"

# Start and enable Docker
systemctl enable --now docker
usermod -aG docker ec2-user

# Install kubectl
# Use the latest stable version of kubectl
# If the curl command fails, default to a specific version
VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

# Check if empty or invalid (not starting with "v")
if [[ -z "$VERSION" || ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "⚠️ Failed to fetch a valid Kubernetes version. Falling back to v1.33.2"
  VERSION="v1.33.2"
fi

curl -LO https://dl.k8s.io/release/${VERSION}/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube (as ec2-user)
# Minimum memory in MB required to start minikube safely
MIN_MEM=2048

while true; do
  # Check available memory
  available_mem=$(free -m | awk '/Mem:/ {print $7}')
  echo "Available memory: ${available_mem}MB"

  if [ "$available_mem" -ge "$MIN_MEM" ]; then
    echo "Enough memory available, starting Minikube..."
    
    #This starts a new shell with the docker group applied
    newgrp docker

    runuser -l ec2-user -c "minikube start --driver=docker --cpus=2 --memory=${MIN_MEM}"
    break
  else
    echo "Not enough memory, waiting 10 seconds before retrying..."
    sleep 10
  fi
done
#runuser -l ec2-user -c 'minikube start --driver=docker --cpus=2 --memory=2048'

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
