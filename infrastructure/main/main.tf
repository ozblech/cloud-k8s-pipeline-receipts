// ------------------------
// Modules
// -------------------------
module "vpc" {
  source = "../Vpc"
  vpc_cidr       = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  vpc_name = var.vpc_name
  aws_availability_zones = data.aws_availability_zones.available.names
}

module "iam" {
  source = "../Iam"
  github_repo = var.github_repo
  minikube_ec2_tag_name = module.ec2.minikube_ec2_tag_name
  minikube_ec2_id = module.ec2.minikube_ec2_id
  region = var.region
}

module "security_groups" {
  source = "../SecurityGroups"
  vpc_id             = module.vpc.vpc_id
  my_ip              = var.my_ip
}

module "ec2" {
  source = "../Ec2"
  public_key_location       = var.public_key_location
  postgres_ec2_private_ip   = var.postgres_ec2_private_ip
  public_subnet_ids         = module.vpc.public_subnet_ids
  private_subnet_ids        = module.vpc.private_subnet_ids
  minikube_sg_id            = module.security_groups.minikube_sg_id
  postgres_sg_id            = module.security_groups.postgres_sg_id
  minikube_profile          = module.iam.minikube_profile
  postgres_profile          = module.iam.postgres_profile
  ami_name_filter           = var.ami_name_filter
}

module "s3" {
  source = "../S3"
  s3_bucket_name = var.s3_bucket_name
  minikube_role_arn  = module.iam.minikube_role_arn
}
