# 🚀 Cloud K8s Pipeline for Receipts API

This repository provisions AWS infrastructure with Terraform, deploys a Helm chart to a Minikube cluster running on EC2, and updates the app automatically when changes are pushed to the `master` branch.

---

## 1️⃣ Configure GitHub Actions Secrets & Variables

Before running any workflows, make sure your GitHub repository has the following **Secrets** and **Variables** set.

### GitHub **Secrets** (Repository Settings → Secrets and variables → Actions → Secrets)
| Name                  | Example Value / Notes                               |
|-----------------------|-----------------------------------------------------|
| `AWS_ACCOUNT_ID`      | Your AWS account ID (12 digits)                     |
| `AWS_REGION`          | AWS region, e.g. `us-west-2`                        |
| `DOCKERHUB_TOKEN`     | Docker Hub access token                             |
| `DOCKERHUB_USERNAME`  | Docker Hub username                                 |
| `S3_BUCKET_NAME`      | Your S3 bucket for Helm chart storage + receipts    |

---

### GitHub **Variables** (Repository Settings → Secrets and variables → Actions → Variables)
| Name                     | Example Value                                              |
|--------------------------|------------------------------------------------------------|
| `DEPLOYMENT_NAME`        | `receipts-api`                                             |
| `IMAGE_REPO`             | `ozblech/receipts-api`                                     |
| `KUBECONFIG_PATH`        | `/home/ec2-user/.kube/config`                              |
| `MINIKUBE_EC2_TAG_NAME`  | Tag used to find your EC2 in AWS (e.g. `minikube-ec2`)     |

---

## 2️⃣ Set Terraform Variables

Edit the `terraform.tfvars` file in the root of your Terraform project:

```hcl
public_key_location     = ""  # Path to your SSH public key
github_repo             = "username/cloud-k8s-pipeline-receipts"
region                  = ""  # AWS region, e.g., us-west-2
postgres_ec2_private_ip = "" # Private IP of your Postgres EC2 instance
db_user                 = ""
db_password             = ""
s3_bucket_name          = ""
db_connection_string    = "dbname='receipts' host='10.0.3.100'"
secret_name             = "receipts-app-secrets"

aws_access_key_id       = ""
aws_secret_access_key   = ""
