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

############### Prometheus Operator Setup ###############
# Deploy Prometheus Operator using Helm
runuser -l ec2-user -c '
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update

  helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace
'

# Wait for Prometheus pods to be ready
runuser -l ec2-user -c '
  echo "Waiting for Prometheus components to be ready..."
  kubectl wait --namespace monitoring \
    --for=condition=Ready pod \
    --selector=app.kubernetes.io/instance=kube-prometheus-stack \
    --timeout=180s
'

# Apply ServiceMonitor to monitor Minikube components
runuser -l ec2-user -c '
  cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kubelet
  namespace: monitoring
spec:
  selector:
    matchLabels:
      component: kubelet
  namespaceSelector:
    matchNames:
      - kube-system
  endpoints:
  - port: http-metrics
    interval: 15s
EOF
'

# Verify Prometheus is scraping metrics
runuser -l ec2-user -c '
  echo "Prometheus targets:"
  kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090 &
  sleep 5
  curl -s http://localhost:9090/api/v1/targets | jq ".data.activeTargets[] | {job: .labels.job, health: .health}" || echo "Target check failed"
  pkill -f "kubectl port-forward"