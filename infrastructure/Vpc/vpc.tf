// ------------------------
// vpc
// ------------------------
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
    availability_zone               = var.aws_availability_zones[count.index]
}

resource "aws_subnet" "private_subnets" {
    count                           = length(var.private_subnet_cidrs)
    vpc_id                          = aws_vpc.my_vpc.id
    cidr_block                      = var.private_subnet_cidrs[count.index]
    availability_zone               = var.aws_availability_zones[count.index]
}

// Internet gateway
resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id
}

// Route table
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }
    tags = {
        Name: "my-route-table"
    }

}

// Route table for private subnets
// This route table will be used for private subnets to route traffic through the NAT gateway
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-route-table"
  }
}

// Routing association
resource "aws_route_table_association" "public" {
  for_each       = { for idx, subnet in aws_subnet.public_subnets : idx => subnet.id }
  subnet_id      = each.value
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private" {
  for_each       = { for idx, subnet in aws_subnet.private_subnets : idx => subnet.id }
  subnet_id      = each.value
  route_table_id = aws_route_table.private_rt.id
}

// NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id // Use the first public subnet for the NAT gateway

  tags = {
    Name = "nat-gateway"
  }

  depends_on = [aws_internet_gateway.my_igw] // Ensure the internet gateway is created before the NAT gateway
}

// Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "nat-eip"
  }
}

