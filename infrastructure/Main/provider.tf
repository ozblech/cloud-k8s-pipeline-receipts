// ------------------------
// provider
// ------------------------
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


// This data source queries AWS to get a list of currently available Availability Zones in the region.
data "aws_availability_zones" "available" {
  state = "available"
}
