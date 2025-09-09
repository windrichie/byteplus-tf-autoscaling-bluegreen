locals {
  project_name = "tf-asg-demo"
}

# ECS Key Pair
data "byteplus_ecs_key_pairs" "default_key_pair" {
  key_pair_name = var.key_pair_name
}

# Security Group for ECS instances
resource "byteplus_security_group" "app_sg" {
  vpc_id              = byteplus_vpc.main.id
  security_group_name = "${local.project_name}-app-sg"
}

resource "byteplus_security_group_rule" "app_sg_ingress_http" {
  security_group_id = byteplus_security_group.app_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_start        = "80"
  port_end          = "80"
  cidr_ip           = "0.0.0.0/0"
  description       = "allow ingress HTTP port"
}

resource "byteplus_security_group_rule" "app_sg_ingress_ssh" {
  security_group_id = byteplus_security_group.app_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_start        = "22"
  port_end          = "22"
  cidr_ip           = "0.0.0.0/0"
  description       = "allow ingress SSH port"
}

resource "byteplus_security_group_rule" "app_sg_egress" {
  security_group_id = byteplus_security_group.app_sg.id
  direction         = "egress"
  protocol          = "all"
  port_start        = "-1"
  port_end          = "-1"
  cidr_ip           = "0.0.0.0/0"
}

data "byteplus_images" "ubuntu22" {
  name_regex = "Ubuntu 22.04 64 bit"
}