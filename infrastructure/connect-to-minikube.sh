set -e

EC2_USER=ec2-user
EC2_IP=$(terraform output -raw minikube_ec2_public_ip)
REMOTE_KUBECONFIG='~/.kube/config'
LOCAL_DIR=./minikube-ec2
ABS_DIR=$(realpath "$LOCAL_DIR")
CONFIG_FILE_NAME="minikube-ec2-config"
CONFIG_FILE_PATH="$ABS_DIR/$CONFIG_FILE_NAME"

echo "⏳ Waiting for Minikube to be ready on EC2..."

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
ssh -f -N -L 8443:$MINIKUBE_IP:8443 $EC2_USER@$EC2_IP

# Export kubeconfig so kubectl uses it
export KUBECONFIG="$CONFIG_FILE_PATH"
echo "✅ KUBECONFIG is set to: $KUBECONFIG"

# 🟢 All set
echo "✅ Run this to test kubectl:"
echo "kubectl get nodes"
 
 # 🔍 Test kubectl access
echo "🔍 Testing kubectl access..."
kubectl get nodes || echo "❌ Failed to connect to Minikube. Check your SSH tunnel and certs."
