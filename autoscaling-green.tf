# Load Balancer resources
resource "byteplus_clb" "app_clb_green" {
  type               = "public"
  subnet_id          = byteplus_subnet.subnet_1a.id
  load_balancer_name = "${local.project_name}-clb-green"
  load_balancer_spec = "small_1"
  eip_billing_config {
    isp              = "BGP"
    eip_billing_type = "PostPaidByTraffic"
    bandwidth        = 100
  }
}

resource "byteplus_listener" "http_listener_green" {
  load_balancer_id = byteplus_clb.app_clb_green.id
  listener_name    = "http-listener-green"
  protocol         = "HTTP"
  port             = 80
  server_group_id  = byteplus_server_group.app_server_group_green.id
  enabled          = "on"

  health_check {
    enabled              = "on"
    interval             = 10
    timeout              = 5
    healthy_threshold    = 3
    un_healthy_threshold = 5
    http_code            = "http_2xx"
    method               = "GET"
    uri                  = "/"
  }
}

# Autoscaling Group Resources
resource "byteplus_scaling_group" "asg_green" {
  scaling_group_name        = "${local.project_name}-asg-green"
  subnet_ids                = [byteplus_subnet.subnet_1a.id, byteplus_subnet.subnet_1b.id]
  multi_az_policy           = "BALANCE"
  min_instance_number       = 1
  max_instance_number       = 5
  desire_instance_number    = 2
  default_cooldown          = 60
  instance_terminate_policy = "OldestInstance"
  server_group_attributes {
    port            = 80
    server_group_id = byteplus_server_group.app_server_group_green.id
    weight          = 100
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "byteplus_scaling_configuration" "scaling_config_green" {
  scaling_configuration_name = "${local.project_name}-scaling-config-green"
  scaling_group_id           = byteplus_scaling_group.asg_green.id
  image_id                   = [for image in data.byteplus_images.ubuntu22.images : image.image_id if image.image_name == "Ubuntu 22.04 64 bit"][0]
  instance_types             = ["ecs.g3i.large"]
  instance_name              = "${local.project_name}-instance-green"
  key_pair_name              = data.byteplus_ecs_key_pairs.default_key_pair.key_pairs[0].key_pair_name
  security_group_ids         = [byteplus_security_group.app_sg.id]
  eip_bandwidth              = 50
  eip_isp                    = "BGP"
  eip_billing_type           = "PostPaidByTraffic"

  volumes {
    volume_type          = "ESSD_PL0"
    size                 = 20
    delete_with_instance = true
  }
  volumes {
    volume_type          = "ESSD_PL0"
    size                 = 50
    delete_with_instance = true
  }

  user_data = base64encode(file("scripts/userdata-green.sh"))

  lifecycle {
    create_before_destroy = true
  }
}

# Attach scaling configurations to scaling groups
resource "byteplus_scaling_configuration_attachment" "asg_attach_green" {
  scaling_configuration_id = byteplus_scaling_configuration.scaling_config_green.id

  depends_on = [byteplus_scaling_group.asg_green, byteplus_scaling_configuration.scaling_config_green]
}

# Enable scaling groups
resource "byteplus_scaling_group_enabler" "asg_enable_green" {
  scaling_group_id = byteplus_scaling_group.asg_green.id

  depends_on = [
    byteplus_scaling_configuration_attachment.asg_attach_green
  ]
}

# CPU-based scaling policy
resource "byteplus_scaling_policy" "asg_cpu_policy_green" {
  active              = true
  scaling_group_id    = byteplus_scaling_group.asg_green.id
  scaling_policy_name = "${local.project_name}-cpu-policy-green"
  scaling_policy_type = "Alarm"
  adjustment_type     = "PercentChangeInCapacity"
  adjustment_value    = 20
  cooldown            = 10

  alarm_policy_rule_type                     = "Static"
  alarm_policy_evaluation_count              = 1
  alarm_policy_condition_metric_name         = "Instance_CpuBusy_Avg"
  alarm_policy_condition_metric_unit         = "Percent"
  alarm_policy_condition_comparison_operator = ">"
  alarm_policy_condition_threshold           = 70

  depends_on = [
    byteplus_scaling_group_enabler.asg_enable_green
  ]
}

resource "byteplus_server_group" "app_server_group_green" {
  load_balancer_id  = byteplus_clb.app_clb_green.id
  server_group_name = "${local.project_name}-server-group-green"
}