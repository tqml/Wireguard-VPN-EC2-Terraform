variable "region" {
  description = "The region to use for the deployment."
  type        = string
}

variable "tags" {
  description = "Tags that will be applied to the instance"
  type        = map(string)
}

variable "vpc_cidr_block" {
  description = "The private IP block of the VPC according to RFC1918."
  type        = string
}
variable "security_group_rules_4" {
  description = "The ipv4 rules of the security group."
  type = map(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable "security_group_rules_6" {
  description = "The ipv6 rules of the security group."
  type = map(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable "ssh_public_key" {
  description = "The SSH public key"
  type        = string
}

variable "ubuntu_ami" {
  type = string
}

variable "instance_type" {
  type = string
}
