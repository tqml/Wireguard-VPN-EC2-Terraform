
resource "aws_vpc" "this" {
  cidr_block                       = var.vpc_cidr_block
  assign_generated_ipv6_cidr_block = true
  enable_dns_support               = true
  enable_dns_hostnames             = true
  tags = {
    Name = "VPN-VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id                                         = aws_vpc.this.id
  cidr_block                                     = cidrsubnet(aws_vpc.this.cidr_block, 8, 0)
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.this.ipv6_cidr_block, 8, 0)
  map_public_ip_on_launch                        = true
  assign_ipv6_address_on_creation                = true
  enable_resource_name_dns_a_record_on_launch    = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  private_dns_hostname_type_on_launch            = "resource-name"
  tags = {
    Name = "VPN-Subnet"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "VPN-IGW"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "VPN-RTB"
  }
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_route" "public_4" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route" "public_6" {
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this.id

}


# %% --- Security Group ------------------------------------------


resource "aws_security_group" "vpn" {
  vpc_id      = aws_vpc.this.id
  name_prefix = "VPN-"
  description = "A security group for our VPN tunnel"
  tags        = { Name = "VPN-SG" }
}

resource "aws_security_group_rule" "vpn_4" {
  for_each          = var.security_group_rules_4
  security_group_id = aws_security_group.vpn.id
  description       = each.key
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  type              = each.value.type
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
}

resource "aws_security_group_rule" "vpn_6" {
  for_each          = var.security_group_rules_6
  security_group_id = aws_security_group.vpn.id
  description       = each.key
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  type              = each.value.type
  protocol          = each.value.protocol
  ipv6_cidr_blocks  = each.value.cidr_blocks
}


# %% --- Load the local file ------------------------------------------


data "local_file" "user_data" {
  filename = "${path.module}/../scripts/user_data.sh"
}

# %% --- Create the EC2 Instance ------------------------------------------

resource "aws_key_pair" "vpn" {
  key_name_prefix = "vpn"
  public_key      = var.ssh_public_key
}

resource "aws_instance" "vpn" {
  instance_type = var.instance_type
  key_name      = aws_key_pair.vpn.key_name
  ami           = var.ubuntu_ami
  monitoring    = true

  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.vpn.id]
  iam_instance_profile   = aws_iam_instance_profile.vpn_cloudwatch.name

  user_data                   = data.local_file.user_data.content
  user_data_replace_on_change = true

  tags = {
    Name = "VPN"
  }
}


# %% --- Extras Ubuntu ------------------------------------------

data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id "
}



# %% --- Extras ------------------------------------------


resource "aws_sns_topic" "vpn" {
  name_prefix = "vpn-"
  fifo_topic  = false
}

resource "aws_iam_role" "vpn_cloudwatch" {
  name_prefix        = "VPN-CloudWatchAgentServerRole-"
  description        = "IAM Role for CW on EC2"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_instance_profile" "vpn_cloudwatch" {
  name_prefix = "VPN-CloudWatchAgentServerRole-"
  role        = aws_iam_role.vpn_cloudwatch.name
}

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "CloudWatchAgentServerPolicy" {
  name = "CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  role       = aws_iam_role.vpn_cloudwatch.name
  policy_arn = data.aws_iam_policy.CloudWatchAgentServerPolicy.arn
}


