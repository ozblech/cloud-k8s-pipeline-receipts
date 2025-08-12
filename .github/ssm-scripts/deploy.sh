#!/bin/bash
set -euo pipefail

echo "=== Starting deployment script ==="

# Download Helm chart from S3
echo "Downloading Helm chart from S3..."
aws s3 cp "s3://${S3_BUCKET_NAME}/helm_chart.tar.gz" /tmp/helm_chart.tar.gz --region "${AWS_REGION}"
mkdir -p /helm_chart/
tar -xzvf /tmp/helm_chart.tar.gz -C /helm_chart/

# Set kubeconfig
export KUBECONFIG="${KUBECONFIG_PATH}"

# Fetch secrets
echo "Fetching secrets from AWS Secrets Manager..."
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "${SECRET_NAME}" \
  --query SecretString \
  --output text \
  --region "${AWS_REGION}")

DB_USER=$(echo "$SECRET_JSON" | jq -r .db_user)
DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r .db_password)
DB_CONN=$(echo "$SECRET_JSON" | jq -r .db_connection_string)
AWS_KEY_ID=$(echo "$SECRET_JSON" | jq -r .AWS_ACCESS_KEY_ID)
AWS_SECRET=$(echo "$SECRET_JSON" | jq -r .AWS_SECRET_ACCESS_KEY)

# Create secret.yaml file
echo "Creating values-secret.yaml file..."
cat <<EOF > /helm_chart/values-secret.yaml
secret:
  db_user: "$DB_USER"
  db_password: "$DB_PASSWORD"
  s3_bucket_name: "$S3_BUCKET_NAME"
  s3_region: "${AWS_REGION}"
  db_connection_string: "$DB_CONN"

aws:
  AWS_ACCESS_KEY_ID: "$AWS_KEY_ID"
  AWS_SECRET_ACCESS_KEY: "$AWS_SECRET"
EOF

chmod 600 /helm_chart/values-secret.yaml

# Deploy Helm chart
echo "Deploying new Docker image..."
helm upgrade "${DEPLOYMENT_NAME}" /helm_chart \
  --install \
  --namespace default \
  -f /helm_chart/values.yaml \
  -f /helm_chart/values-secret.yaml \
  --set image.repository="${IMAGE_REPO}" \
  --set image.tag="${IMAGE_TAG}"

# Wait for rollout
kubectl rollout status "deployment/${DEPLOYMENT_NAME}" -n default --timeout=60s \
  || { echo "Rollout failed"; exit 1; }

# Label deployment
kubectl label deployment/"${DEPLOYMENT_NAME}" version="${IMAGE_TAG}" --overwrite

# Delete secret file
rm -f /helm_chart/values-secret.yaml

# Cleanup old Docker images
echo "Cleaning up old Docker images..."
runuser -l ec2-user -c "minikube ssh -- docker system prune -a -f"

echo "=== Deployment completed successfully ==="
