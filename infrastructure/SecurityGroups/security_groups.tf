// ------------------------
// security_groups
// -------------------------
resource "aws_security_group" "postgres_sg" {
    name            = "postgres_sg"
    description     = "Allow incoming traffic only from the Minikube EC2 SG on the PostgreSQL port (5432)" 
    vpc_id          = var.vpc_id
    tags = {
        Name = "postgres_sg"
    }

    ingress {
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        security_groups = [aws_security_group.minikube_sg.id] 
    }

    // Only allows outbound HTTPS traffic (TCP 443). If your setup_postgres.sh only needs to download packages or files over HTTPS, this is all you need.
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
    vpc_id          = var.vpc_id
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

    # ingress {
    #     description = "SSH access from github actions"
    #     from_port   = 22
    #     to_port     = 22
    #     protocol    = "tcp"
    #     cidr_blocks = ["0.0.0.0/0"] // Allow SSH from anywhere (for testing purposes)
    # }

    ingress {
    description = "Kubernetes API access"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] // My IP
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
} 
