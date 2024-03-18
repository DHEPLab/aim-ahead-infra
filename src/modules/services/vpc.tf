resource "aws_vpc" "vpc" {
  cidr_block           = local.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc-${var.env}"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.private_subnet_cidr_blocks[0]
  availability_zone = local.availability_zones[0]

  tags = {
    "Name" = "${var.project_name}-private-subnet-1-${var.env}"
  }
}

#trivy:ignore:AVD-AWS-0164
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.public_subnet_cidr_blocks[0]
  availability_zone       = local.availability_zones[0]
  map_public_ip_on_launch = var.env == "prod" ? false : true

  tags = {
    "Name" = "${var.project_name}-public-subnet-1-${var.env}"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.private_subnet_cidr_blocks[1]
  availability_zone = local.availability_zones[1]

  tags = {
    "Name" = "${var.project_name}-private-subnet-2-${var.env}"
  }
}

#trivy:ignore:AVD-AWS-0164
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.public_subnet_cidr_blocks[1]
  availability_zone       = local.availability_zones[1]
  map_public_ip_on_launch = var.env == "prod" ? false : true

  tags = {
    "Name" = "${var.project_name}-public-subnet-2-${var.env}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-igw-${var.env}"
  }
}


resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${var.env}"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.env}"
  }
}

resource "aws_route_table_association" "private_subnet_1_associate" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_2_associate" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "public_subnet_1_associate" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_associate" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IP resource.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip-${var.env}"
  }
}

# VPC NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "${var.project_name}-nat-gw-${var.env}"
  }

  depends_on = [aws_internet_gateway.igw]
}
