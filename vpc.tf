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

resource "byteplus_eip_address" "natgw_eip" {
  name         = "${local.project_name}-nat-gw-eip"
  bandwidth    = 200
  billing_type = "PostPaidByTraffic"
  isp          = "BGP"
}

resource "byteplus_eip_associate" "natgw_eip_association" {
  allocation_id = byteplus_eip_address.natgw_eip.id
  instance_id   = byteplus_nat_gateway.main.id
  instance_type = "Nat"
}

resource "byteplus_snat_entry" "natgw_snat_entry_subnet1a" {
  snat_entry_name = "${local.project_name}-snat-entry"
  nat_gateway_id  = byteplus_nat_gateway.main.id
  eip_id          = byteplus_eip_address.natgw_eip.id
  subnet_id       = byteplus_subnet.subnet_1a.id
  depends_on      = [ byteplus_eip_associate.natgw_eip_association ]
}

resource "byteplus_snat_entry" "natgw_snat_entry_subnet1b" {
  snat_entry_name = "${local.project_name}-snat-entry"
  nat_gateway_id  = byteplus_nat_gateway.main.id
  eip_id          = byteplus_eip_address.natgw_eip.id
  subnet_id       = byteplus_subnet.subnet_1b.id
  depends_on      = [ byteplus_eip_associate.natgw_eip_association ]
}