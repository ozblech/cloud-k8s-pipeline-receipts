# 🚀 Cloud K8s Pipeline for Receipts API

This repository provisions AWS infrastructure with Terraform, deploys a Helm chart to a Minikube cluster running on EC2, and sets up a CI/CD pipeline with GitHub Actions to automatically build, push, and deploy the application.

---

## 1️⃣ Configure GitHub Actions Secrets & Variables

Before running any workflows, make sure your GitHub repository has the following **Secrets** and **Variables** set.

🔑 GitHub Secrets
(Repository Settings → Secrets and variables → Actions → Secrets)
| Name                  | Example Value / Notes                               |
|-----------------------|-----------------------------------------------------|
| `AWS_ACCOUNT_ID`      | Your AWS account ID (12 digits)                     |
| `AWS_REGION`          | AWS region, e.g. `us-west-2`                        |
| `DOCKERHUB_TOKEN`     | Docker Hub access token                             |
| `DOCKERHUB_USERNAME`  | Docker Hub username                                 |
| `S3_BUCKET_NAME`      | Your S3 bucket for Helm chart storage + receipts    |

---

⚙️ GitHub Variables
(Repository Settings → Secrets and variables → Actions → Variables)
| Name                     | Example Value                                              |
|--------------------------|------------------------------------------------------------|
| `DEPLOYMENT_NAME`        | `receipts-api`                                             |
| `IMAGE_REPO`             | `ozblech/receipts-api`                                     |
| `KUBECONFIG_PATH`        | `/home/ec2-user/.kube/config`                              |
| `MINIKUBE_EC2_TAG_NAME`  | Tag used to find your EC2 in AWS (e.g. `minikube-ec2`)     |

---

## 2️⃣ Set Terraform Variables

Edit the `terraform.tfvars` file in the root of your Terraform project (⚠️ DO NOT PUSH TO GIT)::

```hcl
public_key_location     = ""  # Path to your SSH public key
github_repo             = "username/cloud-k8s-pipeline-receipts"
region                  = ""  # AWS region, e.g., us-west-2
postgres_ec2_private_ip = "" # Private IP of your Postgres EC2 instance
db_user                 = "" # Base 64 Encoded
db_password             = "" # Base 64 Encoded
s3_bucket_name          = ""
db_connection_string    = "dbname='receipts' host='10.0.3.100'"
secret_name             = "receipts-app-secrets"

aws_access_key_id       = ""
aws_secret_access_key   = ""

```

💡 These values are used both for infrastructure provisioning and application configuration.
Make sure they match the ones you’ve set in GitHub Secrets & Variables.

## 3️⃣ Deploy Infrastructure & Connect to Minikube

Run the deployment script from the infrastructure/main directory:
/deploy-and-connect.sh
This script:

1.Runs terraform apply to provision AWS resources.

2.Waits briefly for services to initialize.

3.Runs connect-to-minikube.sh to set up your kubectl context.


## 4️⃣ CI/CD Pipeline (GitHub Actions)

The repository includes three workflows:

✅ CI – Continuous Integration (Pull Requests → master)

Runs automatically when a Pull Request is opened against master.

Executes unit tests to validate changes.

Ensures only tested code can be merged into master.

🚀 CD – Continuous Deployment (Push → master)

Triggered when new code is merged/pushed into master.

Workflow steps:

1.Bump version automatically.

2.Build a new Docker image of the application.

3.Push the image to Docker Hub, tagged with the new version + commit SHA.

4.Deploy the image to the Minikube EC2 cluster via Helm.

5.Validate rollout with kubectl rollout status.

🔄 Rollback Workflow

A separate workflow allows rolling back the Kubernetes deployment to:

*A specific version (by providing the tag).

*Or the previous working version (default).

📊 Workflow Summary
```pgsql
PR → master   → Run unit tests ✅
Push → master → Bump version → Build → Push image → Deploy 🚀
Rollback      → Revert deployment to previous/specified version 🔄
```

No manual steps required — the pipeline ensures tested, versioned, and continuously deployed releases.

## 5️⃣ Commands to test from local machine

Upload a receipt:

curl -X POST -F "file=@receipts_project/receipts/gcp.txt" http://localhost:5000/upload

Print all receipts:

curl http://localhost:5000/receipts
