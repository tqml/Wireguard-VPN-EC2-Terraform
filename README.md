# Wireguard VPN on EC2

This is an example to see how to deploy Wireguard VPN [^1] to an Amazon EC2 instance.

__IMPORTANT INFO__: 

- The resources that are deployed should be within the AWS Free-Tier (if you don't have more than 100 GB of data per month.) However, this can change in the future and you are responsible for any costs that occur.
- This guide focusses on _simplicity_. To actually use this in production, you should follow best practices and harden your system.


## Deployment Part 1: Deploy AWS Infrastructure with Terraform

> You don't need to do this step with terraform, you could also create the resources yourself in the AWS console.

Go the `terraform` folder and rename the file `terraform.tvars.example` to `terraform.tfvars`. Adapt the

You need Terraform in version 1.3 and an AWS account for the deployment.

```bash

cd terraform

# Initialize terraform
terraform init

# Run a terraform plan
terraform plan

# Terraform apply will deploy the configuration to AWS and create all
# the resources that are specified
terraform apply
```

## Deployment Part 2: Setup VPN

Obtain the IP address of the newly created instance from terraform and ssh into the instance

```bash

# Switch to root user
sudo su

# Go to the wireguard directory
cd /etc/wireguard

# Make sure we set the permission such that we dont leak private keys
umask 077 
touch wg0.conf
```


Open a new Terminal window on your local machine. Execute the bash script `generate-wg-config.sh` (you can also copy it to the server instance, if you cannot do this on your machine). 

__Before you execute the script make sure you changed the IP address and renamed the network interface so it matches your machine.__

```bash
# On the EC2 instance
# Copy and paste the configuration 'wg0.conf'
nano wg0.conf
```

When the configuration has been setup, the VPN can be started:

```bash
# To start the VPN
sudo wg-quick up wg0

# To stop the VPN
sudo wg-quick down wg0
```

If your using the root user, you dont have to use `sudo`.


## Test Site

To check if the VPN works, import an client configuration and visit a test site, e.g.:

https://ipleak.net/

## References

https://stanislas.blog/2019/01/how-to-setup-vpn-server-wireguard-nat-ipv6/#peer-1-server

[^1]: https://www.wireguard.com/

WireGuard is a registered trademark of Jason A. Donenfeld.
