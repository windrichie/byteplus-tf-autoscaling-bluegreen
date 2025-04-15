# VPC
resource "byteplus_vpc" "main" {
  vpc_name   = "${local.project_name}-vpc"
  cidr_block = "10.0.0.0/16"
}

# Subnets
resource "byteplus_subnet" "subnet_1a" {
  subnet_name = "${local.project_name}-vpc-subnet-1a"
  cidr_block  = "10.0.0.0/24"
  zone_id     = "ap-southeast-1a"
  vpc_id      = byteplus_vpc.main.id
}

resource "byteplus_subnet" "subnet_1b" {
  subnet_name = "${local.project_name}-vpc-subnet-1b"
  cidr_block  = "10.0.1.0/24"
  zone_id     = "ap-southeast-1b"
  vpc_id      = byteplus_vpc.main.id
}

# NAT Gateway
resource "byteplus_nat_gateway" "main" {
  vpc_id           = byteplus_vpc.main.id
  subnet_id        = byteplus_subnet.subnet_1a.id
  nat_gateway_name = "${local.project_name}-nat-gw"
  spec             = "Small"

  lifecycle {
    ignore_changes = [tags]
  }
}
