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

resource "aws_vpc" "my_vpc" {
 cidr_block             = var.vpc_cidr
 enable_dns_hostnames   = true
 enable_dns_support     = true
 tags = {
    Name = var.vpc_name
 }
}

resource "aws_subnet" "public_subnets" {
    count                           = length(var.public_subnet_cidrs)
    vpc_id                          = aws_vpc.my_vpc.id
    cidr_block                      = var.public_subnet_cidrs[count.index]
    map_public_ip_on_launch         = true
    availability_zone               = data.aws_availability_zones.available.names[count.index]
}

resource "aws_subnet" "private_subnets" {
    count                           = length(var.private_subnet_cidrs)
    vpc_id                          = aws_vpc.my_vpc.id
    cidr_block                      = var.private_subnet_cidrs[count.index]
    availability_zone               = data.aws_availability_zones.available.names[count.index]
}

// This data source queries AWS to get a list of currently available Availability Zones in the region.
data "aws_availability_zones" "available" {
  state = "available"
}

// Security groups
resource "aws_security_group" "postgres_sg" {
    name            = "postgres_sg"
    description     = "Allow incoming traffic only from the Minikube EC2 SG on the PostgreSQL port (5432)" 
    vpc_id          = aws_vpc.my_vpc.id
    tags = {
        Name = "postgres_sg"
    }

    ingress {
        description = "SSH access"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_ip] // My IP
    }


    ingress {
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        security_groups = [aws_security_group.minikube_sg.id] 
        //cidr_blocks = allow only from private subnets??
        //cidr_blocks = ["0.0.0.0/0"]
    }

    // To test from my machine
    # ingress {
    #     from_port   = 5432
    #     to_port     = 5432
    #     protocol    = "tcp"
    #     cidr_blocks = [var.my_ip] // My IP
    # }

    // Only allows outbound HTTPS traffic (TCP 443).
    egress { 
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
} 

resource "aws_security_group" "minikube_sg" {
    name            = "minikube_sg"
    description     = "Allows incoming SSH and Kubernetes related ports including ports for accessing Minikube services" 
    vpc_id          = aws_vpc.my_vpc.id
    tags = {
        Name = "minikube_sg"
    }

    ingress {
        description = "SSH access"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_ip] // My IP
    }

    ingress {
        description = "SSH access from github actions"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] // Allow SSH from anywhere (for testing purposes)
    }

    ingress {
    description = "Kubernetes API access"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] // My IP
    }

    # ingress {
    #     description = "Node-port access"
    #     from_port   = 30007
    #     to_port     = 30007
    #     protocol    = "tcp"
    #     cidr_blocks =[var.my_ip] // My IP
    # }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
} 

// Route table
resource "aws_route_table" "my_route_table" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }
    tags = {
        Name: "my-route-table"
    }
    
}

// Routing association
resource "aws_route_table_association" "public" {
  for_each       = { for idx, subnet in aws_subnet.public_subnets : idx => subnet.id }
  subnet_id      = each.value
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_route_table_association" "private" {
  for_each       = { for idx, subnet in aws_subnet.private_subnets : idx => subnet.id }
  subnet_id      = each.value
  route_table_id = aws_route_table.my_route_table.id
}

// Internet gateway
resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id

}

// IAM roles
resource "aws_iam_role" "postgres_role" {
  name = "postgres-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "minikube_role" {
  name = "minikube-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

// Attach policies to roles
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.minikube_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.minikube_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

// EC2 instances do not accept IAM roles directly, only instance profiles.
resource "aws_iam_instance_profile" "minikube_profile" {
  name = "minikube-instance-profile"
  role = aws_iam_role.minikube_role.name
}

resource "aws_iam_instance_profile" "postgres_profile" {
  name = "postgres-instance-profile"
  role = aws_iam_role.postgres_role.name
}

//EC2

data "aws_ami" "latest-amazon-linux-image-2023" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name" 
        values = ["al2023-ami-2023.*-x86_64"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

// User has to create a key-pair on his machine and edit the variable public_key_location to point where the public key is
resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = file(var.public_key_location)
}

resource "aws_instance" "minikube_ec2" {
  ami                         = data.aws_ami.latest-amazon-linux-image-2023.id 
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.public_subnets[0].id
  vpc_security_group_ids      = [aws_security_group.minikube_sg.id]
  key_name                    = aws_key_pair.ssh-key.key_name # For SSH access
  iam_instance_profile        = aws_iam_instance_profile.minikube_profile.name
  associate_public_ip_address = true // for ssh

  tags = {
    Name = "minikube-ec2"
    Role = "minikube"
  }

  user_data = file("${path.module}/minikube-bootstrap.sh")
  // cat /var/log/minikube-bootstrap.log
}

# resource "null_resource" "post_apply_script" {
#   provisioner "local-exec" {
#     command = "./connect-to-minikube.sh"
#   }

#   triggers = {
#     always_run = "${timestamp()}"
#   }

#   depends_on = [aws_instance.minikube_ec2]
# }

resource "aws_instance" "postgres_ec2" {
  ami                         = data.aws_ami.latest-amazon-linux-image-2023.id 
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_subnets[0].id
  vpc_security_group_ids      = [aws_security_group.postgres_sg.id]
  key_name                    = aws_key_pair.ssh-key.key_name # For SSH access
  iam_instance_profile        = aws_iam_instance_profile.postgres_profile.name
  associate_public_ip_address = true // for ssh
  private_ip                  = var.postgres_ec2_private_ip // Static private IP for Postgres EC2

  tags = {
    Name = "postgres-ec2"
    Role = "postgres"
  }

  user_data = file("${path.module}/setup_postgres.sh")
  // cat /var/log/postgres-bootstrap.log
}

//This is a static Elastic IP (EIP) you allocate using Terraform and then explicitly associate with your EC2 instance.
//It remains permanently reserved to your account, even if the instance is stopped or recreated (as long as you re-associate it).
# resource "aws_eip" "minikube_eip" {
#   vpc = true
# }

# resource "aws_eip_association" "minikube_eip_assoc" {
#   instance_id   = aws_instance.minikube_ec2.id
#   allocation_id = aws_eip.minikube_eip.id
# }

# // Elastic IP for Minikube EC2
# output "minikube_public_ip" {
#   value       = aws_eip.minikube_eip.public_ip
# }

output minikube_ec2_public_ip {
  value       = aws_instance.minikube_ec2.public_ip
}

output postgres_ec2_public_ip {
  value       = aws_instance.postgres_ec2.public_ip
}

# Generate a random suffix for the bucket name
# resource "random_id" "bucket_suffix" {
#   byte_length = 4
# }

# S3
resource "aws_s3_bucket" "reciepts_bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"

  tags = {
    Name        = "Reciepts Bucket"
  }
}

# OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1" # GitHub Actions thumbprint
  ]
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# Example Policy attachment
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "github-actions-policy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ec2:DescribeInstances",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:DescribeInstanceInformation"
        ],
        Resource = "*"
      }
    ]
  })
}

