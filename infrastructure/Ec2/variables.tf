variable "public_key_location"{
  description = "Location of the public SSH key for EC2 instances"
  type        = string
}

variable "postgres_ec2_private_ip" {
  description = "Private IP address of the PostgreSQL EC2 instance"
  type        = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "minikube_sg_id" {
  description = "Security group ID for Minikube EC2 instance"
  type        = string
}
variable "postgres_sg_id" {
  description = "Security group ID for PostgreSQL EC2 instance"
  type        = string
}

variable "minikube_profile" {
  description = "IAM instance profile for the Minikube EC2 instance"
  type        = string
}

variable "postgres_profile" {
  description = "IAM instance profile for the PostgreSQL EC2 instance"
  type        = string
}

variable "ami_name_filter" {
  description = "Filter for the AMI name to use for EC2 instances"
  type        = string
}

variable "minikube_instance_type" {
  default = "t3.medium"
}

variable "postgres_instance_type" {
  default = "t2.micro"
}