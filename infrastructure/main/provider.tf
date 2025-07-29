// ------------------------
// provider
// ------------------------
terraform {
  required_version = ">= 1.12"
  backend "s3" {
    bucket         = "my-terraform-state-bucket-receipts-app-oz"  # same name as above
    key            = "env/dev/terraform.tfstate"                  # path inside the bucket
    region         = "us-west-2"                                # change as needed
    dynamodb_table = "terraform-locks"                            # same name as above
    encrypt        = true
  }
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
