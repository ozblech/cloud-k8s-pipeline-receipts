# set -o pipefail
#set -e

EC2_USER=ec2-user
EC2_IP=$(terraform output -raw minikube_ec2_public_ip)
REMOTE_KUBECONFIG='~/.kube/config'
LOCAL_DIR=./minikube-ec2
ABS_DIR=$(realpath "$LOCAL_DIR")
CONFIG_FILE_NAME="minikube-ec2-config"
CONFIG_FILE_PATH="$ABS_DIR/$CONFIG_FILE_NAME"

# If EC2_IP is empty, exit with an error
if [ -z "$EC2_IP" ]; then
  echo "❌ Error: EC2 IP address is not set. Please run 'terraform apply' first."
  exit 1
fi

echo "⏳ Waiting for Minikube to be ready on EC2..."
echo "🔗 Connecting to EC2 instance: $EC2_USER@$EC2_IP"

ssh-keyscan -H "$EC2_IP" >> ~/.ssh/known_hosts

until ssh $EC2_USER@$EC2_IP "minikube status | grep -q 'apiserver: Running'"; do
  echo "🔄 Still waiting for Minikube..."
  sleep 5
done

echo "✅ Minikube is running."

mkdir -p "$LOCAL_DIR"

echo "🔐 Copying certs and config..."
echo "Using EC2 user: $EC2_USER"
echo "Using EC2 IP: $EC2_IP"
echo "Using remote kubeconfig: $REMOTE_KUBECONFIG"
echo "Using local directory: $LOCAL_DIR"
echo "Using config file name: $CONFIG_FILE_NAME"

scp $EC2_USER@$EC2_IP:$REMOTE_KUBECONFIG $CONFIG_FILE_PATH
echo "📂 Local kubeconfig saved as: $CONFIG_FILE_PATH"
scp $EC2_USER@$EC2_IP:~/.minikube/ca.crt $LOCAL_DIR/
echo "📜 CA certificate saved as: $LOCAL_DIR/ca.crt"
scp $EC2_USER@$EC2_IP:~/.minikube/profiles/minikube/client.{crt,key} $LOCAL_DIR/
echo "🔑 Client certificate and key saved as: $LOCAL_DIR/client.crt and $LOCAL_DIR/client.key
"
echo "🛠️ Patching kubeconfig..."
sed -i "s|certificate-authority:.*|certificate-authority: $ABS_DIR/ca.crt|" "$CONFIG_FILE_PATH"
sed -i "s|client-certificate:.*|client-certificate: $ABS_DIR/client.crt|" "$CONFIG_FILE_PATH"
sed -i "s|client-key:.*|client-key: $ABS_DIR/client.key|" "$CONFIG_FILE_PATH"
sed -i "s|server:.*|server: https://127.0.0.1:8443|" "$CONFIG_FILE_PATH"

# 🔍 Get Minikube internal IP from EC2
MINIKUBE_IP=$(ssh $EC2_USER@$EC2_IP "minikube ip")
echo "📡 Minikube IP inside EC2: $MINIKUBE_IP"

# 🚪 Start SSH tunnel to forward port 8443 from your local to Minikube
# If port 8443 is in use skip this step
if lsof -i :8443; then
  echo "⚠️ Port 8443 is already in use. Skipping SSH tunnel setup."
else
  echo "🔗 Setting up SSH tunnel to forward port 8443..."
  ssh -f -N -L 8443:$MINIKUBE_IP:8443 $EC2_USER@$EC2_IP
fi

# Export kubeconfig so kubectl uses it
export KUBECONFIG="$CONFIG_FILE_PATH"
echo "✅ KUBECONFIG is set to: $KUBECONFIG"

# 🚪 Start SSH tunnel to forward port 30007 from your local to minikube ip
# If port 5000 is in use skip this step
if lsof -i :5000; then
  echo "⚠️ Port 5000 is already in use. Skipping SSH tunnel setup for port 5000."
else
  echo "🔗 Setting up SSH tunnel to forward port 5000..."
  ssh $EC2_USER@$EC2_IP -f -L 5000:$MINIKUBE_IP:30007 -N
fi

# 🟢 All set
echo "✅ Run this to test kubectl:"
echo "kubectl get nodes"

 
 # 🔍 Test kubectl access
echo "🔍 Testing kubectl access..."
kubectl get nodes || echo "❌ Failed to connect to Minikube. Check your SSH tunnel and certs."

# Kubectl apply all files in receipts_project/kubernetes
# echo "🔄 Applying Kubernetes manifests..."
# kubectl apply -f ../receipts_project/kubernetes/
# echo "✅ Kubernetes manifests applied successfully."


# Check if values-secret.yaml exists
if [ -f ../../receipts_project/helm_chart/values-secret.yaml ]; then
  echo "🔍 values-secret.yaml exists. Proceeding with Helm upgrade..."
  # Helm install all charts in receipts_project/helm
  echo "🔄 Installing Helm charts..."
  helm upgrade --install receipts-api ../../receipts_project/helm_chart -f ../../receipts_project/helm_chart/values.yaml -f ../../receipts_project/helm_chart/values-secret.yaml
fi


# Wait for Prometheus to be ready
echo "⏳ Waiting for Prometheus pod to be Running..."
until kubectl get pod -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].status.phase}' | grep -q "Running"; do
  echo "⌛ Still waiting..."
  sleep 5
done

# 🚪 Port-forward port 9090 for prometheus service
echo "🔗 Port-forwarding Prometheus service on port 9090..."
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring &


# Run this script with: source connect-to-minikube.sh
# so that the KUBECONFIG variable is set in the current shell session.
# or run export KUBECONFIG=./infrastructure/main/minikube-ec2/minikube-ec2-config

