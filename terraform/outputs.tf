output "instance_public_ip_4" {
  description = "The public ipv4 addresses of the instance"
  value       = aws_instance.vpn.public_ip
}

output "instance_public_dns" {
  value = aws_instance.vpn.public_dns
}

output "instance_public_ip6" {
  description = "The ipv6 addresses of the instance"
  value       = aws_instance.vpn.ipv6_addresses
}

output "instance_private_dns" {
  value = aws_instance.vpn.private_dns
}


# %% --- Extra ------------------------------------------

output "ubuntu_ami" {
  description = "The AMI of ubuntu from the parameter store"
  value       = nonsensitive(data.aws_ssm_parameter.ubuntu.value)
}
