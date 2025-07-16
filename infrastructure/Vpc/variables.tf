variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "my-vpc"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16" // for addresses 10.0.0.1 - 10.0.255.254 Network:   10.0.0.0/16   Broadcast: 10.0.255.255 
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "aws_availability_zones" {
  description = "List of availability zones in the region"
  type        = list(string)
}
