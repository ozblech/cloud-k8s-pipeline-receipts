#!/bin/bash

set -euo pipefail

echo "🚀 Starting Terraform apply..."
terraform apply --auto-approve

echo "✅ Terraform apply completed."

echo "🔗 Running connection script: ./connect-to-minikube.sh..."
./connect-to-minikube.sh

echo "🎉 All done!"
