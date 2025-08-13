variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-west-2" // Change as needed
}

variable "vpc_cidr" {
  default = "10.0.0.0/16" // for addresses 10.0.0.1 - 10.0.255.254 Network:   10.0.0.0/16   Broadcast: 10.0.255.255 
}

variable "vpc_name" {
  default = "my-vpc"
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "ami_name_filter"{
  description = "Filter for the AMI name to use for EC2 instances"
  type        = string
  default = "al2023-ami-2023.*-x86_64"
}

variable "public_key_location"{
}

# variable "aws_account_id" {
#   description = "Your AWS account ID"
#   type        = string
# }

variable "github_repo" {
  description = "GitHub repo in the format: org/repo"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for storing app data"
  type        = string
}

variable "s3_backend_bucket_name" {
  description = "Name of the S3 bucket for storing Terraform state"
  type        = string
  default     = "my-terraform-state-bucket-receipts-app-oz"
}

variable "postgres_ec2_private_ip" {
  description = "Private IP address of the PostgreSQL EC2 instance"
  type        = string
}

variable "db_user" {
  description = "Database username encoded in base64 for PostgreSQL"
  type        = string
}
variable "db_password" {
  description = "Database password encoded in base64 for PostgreSQL"
  type        = string
}
variable "db_connection_string" {
  description = "Database connection string"
  type        = string
}
variable "s3_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "us-west-2" // Change as needed
}
variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
}
variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
}
variable "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  type        = string
}