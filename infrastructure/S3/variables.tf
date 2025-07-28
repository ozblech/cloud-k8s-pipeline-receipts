variable "s3_bucket_name" {
  description = "Name of the S3 bucket for storing app data"
  type        = string
}

variable "minikube_role_arn" {
  type        = string
  description = "ARN of the IAM role allowed to access the bucket"
}