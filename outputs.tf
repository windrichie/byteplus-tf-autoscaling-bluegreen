output "blue_clb_public_ip" {
  value = byteplus_clb.app_clb_blue.eip_address
}

output "green_clb_public_ip" {
  value = byteplus_clb.app_clb_green.eip_address
}