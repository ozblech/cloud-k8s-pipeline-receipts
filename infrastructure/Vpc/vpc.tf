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

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = { Name = "${var.vpc_name}-public-rt" }
}

# Private Route Table (no IGW)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id
  tags = { Name = "${var.vpc_name}-private-rt" }
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

