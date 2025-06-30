variable "region" {
  default = "us-west-2"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16" // for addresses 10.0.0.1 - 10.0.255.254 Network:   10.0.0.0/16   Broadcast: 10.0.255.255 
}


variable "vpc_name" {
  default = "my-vpc"
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "ami_id"{
    default = ""
}

variable "my_ip"{
}

variable "public_key_location"{
}
