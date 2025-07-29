variable "github_repo" {
  description = "GitHub repo in the format: <owner>/<repo>"
  type        = string
}

variable "minikube_ec2_tag_name" {
  description = "Tag name for the Minikube EC2 instance"
  type        = string
}

variable "minikube_ec2_id" {
  description = "ID of Minikube EC2 instance"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}