terraform {
  required_version = ">= 1.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# main.tf
resource "aws_vpc" "my_vpc" {
 cidr_block = var.vpc_cidr
}


