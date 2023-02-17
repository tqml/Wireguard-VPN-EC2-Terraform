#!/bin/bash

apt update && apt upgrade -y
apt install -y wireguard wireguard-tools zsh git curl wget nano htop awscli

# Create folder and file
mkdir -p /etc/wireguard


# Enable ip forwarding for ipv4 and ipv6
echo "net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1" > /etc/sysctl.d/wg.conf
sysctl --system



# Install the cloudwatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb