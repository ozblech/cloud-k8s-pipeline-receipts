// ------------------------
// ec2
// ------------------------
data "aws_ami" "latest-amazon-linux-image-2023" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name" 
        values = [var.ami_name_filter] // e.g., "al2023-ami-2023.*-x86_64"  
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
  instance_type               = var.minikube_instance_type
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [var.minikube_sg_id]
  key_name                    = aws_key_pair.ssh-key.key_name # For SSH access
  iam_instance_profile        = var.minikube_profile
  associate_public_ip_address = true // for installing packages 

  tags = {
    Name = "minikube-ec2"
    Role = "minikube"
  }

  user_data = file("${path.module}/scripts/minikube-bootstrap.sh")
}

resource "aws_instance" "postgres_ec2" {
  ami                         = data.aws_ami.latest-amazon-linux-image-2023.id 
  instance_type               = var.postgres_instance_type
  subnet_id                   = var.private_subnet_ids[0]
  vpc_security_group_ids      = [var.postgres_sg_id]
  key_name                    = aws_key_pair.ssh-key.key_name # For SSH access
  iam_instance_profile        = var.postgres_profile
  associate_public_ip_address = false
  private_ip                  = var.postgres_ec2_private_ip // Static private IP for Postgres EC2

  tags = {
    Name = "postgres-ec2"
    Role = "postgres"
  }

  user_data = templatefile("${path.module}/scripts/setup_postgres.sh", {
    DB_USER_B64     = var.db_user
    DB_PASSWORD_B64 = var.db_password
  })
}
