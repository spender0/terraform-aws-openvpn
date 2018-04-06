<!--
  Title: Awesome Terraform config for OpenVPN server installation on AWS
  Description: Fully automated OpenVPN installation. Don't mess with OpenVPN configs any more. Just one cmd "terraform apply" and you will get your own vpn server.
  Author: spender0
  -->
  
<meta name='keywords' content='terraform, openvpn, free vpn, vpn auto deploy, personal vpn, free aws vpn'>

# Get your personal vpn server with only one "terraform apply".
## Terraform config for the simplest, fastest and automated deploying OpenVPN server on AWS.  

## Features:

1. No need to mess with tons of OpenVPN configs and certificates, all is generated automatically. 

2. Customization of OpenVPN configs is also implemented.

3. AWS Free Tier. During first 12 months of AWS usage you have AWS Free Tier https://aws.amazon.com/free/  
That means if you start OpenVPN using t2.micro (default) you will not pay for that during next 12 months.

4. Installation of OpenVPN is based on the best OpenVPN docker image https://hub.docker.com/r/kylemanna/openvpn/.
Terraform creates aws instance, installs docker, generates all necessary OpenVPN configs and certificates, starts OpenVPN server via docker. 

## Requirements:

1. Create AWS account (if not exists): https://aws.amazon.com/resources/create-account

2. Сreate aws access key and secret key and save them somewhere: https://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html

3. Install terraform on your PC: https://www.terraform.io/downloads.html

4. Make sure you have ssh private and public keys on your PC: https://help.skysilk.com/support/solutions/articles/9000108363-how-to-generate-ssh-keys-on-windows-linux-and-mac-os-x 

5. Terraform provisioner doesn't support ssh private key with password yet.If your id_rsa is ecrypted with password you will need to create temporary copy without password: 
```
cp -p ~.ssh/id_rsa ~.ssh/id_rsa_wp
ssh-keygen -p -f ~.ssh/id_rsa_wp
```
6. Install git on your PC https://git-scm.com/downloads

7. (optional) Install OpenVPN client on your PC: https://openvpn.net/index.php/download/community-downloads.html

8. (optional) Find and install OpenVPN client on your smartphone from applestore or googleplay

## Basic usage
	
1. First start preparations:
```
git clone https://github.com/spender0/terraform-aws-openvpn.git
cd terraform-aws-openvpn
terraform init
```
2. Create OpenVPN server: 
```
terraform apply -var 'access-key=YOUR_AWS_ACCESS_KEY' -var 'secret-key=YOUR_AWS_SECRET_KEY'
```
3. Get .ovpn client settings. In the end of "terraform apply" stdout should be instruction how to get CLIENTSETTINGS.ovpn. e.g.:
```
Don't forget to get client .ovpn settings, execute this:
ssh -i ~/.ssh/id_rsa.pub ec2-user@PUBLICIP cat CLIENTSETTINGS.ovpn > CLIENTSETTINGS.ovpn
```
4. Connect to vpn:
```
$ sudo openvpn CLIENTSETTINGS.ovpn  
```

## Addvanced usage

There are additional parameters that can be changed:

variable "**ssh-public-key-path**" {default = "~/.ssh/id_rsa.pub"}

variable "**ssh-private-key-path**" {default = "~/.ssh/id_rsa"}

variable "**port**" {default = "1194"}

variable "**proto**" {default = "udp"}

variable "**region**" {default = "us-east-1"}

variable "**sg-name**" {default = "terraform-aws-openvpn"}

variable "**key-pair-name**" {default = "terraform-aws-openvpn"}

variable "**instance-name**" {default = "terraform-aws-openvpn"}

variable "**instance-type**" {default = "t2.micro"}

variable "**custom-vpn-settings**" {default = ""}

**custom-vpn-settings** is from https://hub.docker.com/r/kylemanna/openvpn/ and the variable is passed to the end of 
docker run --rm kylemanna/openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM ${var.custom-vpn-settings} 

Possible values:

-e EXTRA_SERVER_CONFIG 

-E EXTRA_CLIENT_CONFIG

-f FRAGMENT 

-n DNS_SERVER ...

-p PUSH ...

-r ROUTE ...

-s SERVER_SUBNET

-2    Enable two factor authentication using Google Authenticator.

-a    Authenticate  packets with HMAC using the given message digest algorithm (auth).

-b    Disable 'push block-outside-dns'

-c    Enable client-to-client option

-C    A list of allowable TLS ciphers delimited by a colon (cipher).

-d    Disable default route

-D    Do not push dns servers

-k    Set keepalive. Default: '10 60'

-m    Set client MTU

-N    Configure NAT to access external server network

-t    Use TAP device (instead of TUN device)

-T    Encrypt packets with the given cipher algorithm instead of the default one (tls-cipher).

-z    Enable comp-lzo compression.

### e.g. to force OpenVPN to pretend it is https service, set client mtu 1400, set sndbuf 0, set rcvbuf 0:
```
terraform apply \
-var 'access-key=YOUR_AWS_ACCESS_KEY' \
-var 'secret-key=YOUR_AWS_SECRET_KEY' \
-var 'port=443' \
-var 'proto=tcp' \
-var 'custom-vpn-settings=-e "sndbuf 0" -e "rcvbuf 0" -m 1400'
```
### Generating .ovpn settings for new user:
```
ssh -i ~/.ssh/id_rsa.pub ec2-user@PUBLICIP sudo docker run -v /opt/openvpn/etc:/etc/openvpn --rm -i kylemanna/openvpn easyrsa build-client-full NEWUSERNAME nopass

ssh -i ~/.ssh/id_rsa.pub ec2-user@PUBLICIP "sudo docker run -v /opt/openvpn/etc:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient NEWUSERNAME > NEWUSERNAME.ovpn"

ssh -i ~/.ssh/id_rsa.pub ec2-user@PUBLICIP cat NEWUSERNAME.ovpn > NEWUSERNAME.ovpn
```
