variable "ssh-public-key-path" {default = "~/.ssh/id_rsa.pub"}
variable "ssh-private-key-path" {default = "~/.ssh/id_rsa"}
variable "port" {default = "1194"}
variable "proto" {default = "udp"}
variable "custom-vpn-settings" {default = ""}
variable "region" {default = "us-east-1"}
variable "sg-name" {default = "terraform-aws-openvpn"}
variable "key-pair-name" {default = "terraform-aws-openvpn"}
variable "instance-name" {default = "terraform-aws-openvpn"}
variable "instance-type" {default = "t2.micro"}

provider "aws" {
  region     = "${var.region}"
}
resource "aws_key_pair" "key-pair" {
  key_name   = "${var.key-pair-name}"
  public_key = "${file("${var.ssh-public-key-path}")}"
}
resource "aws_security_group" "sg" {
  name        = "${var.sg-name}"
  description = "created automatically by https://github.com/spender0/terraform-aws-openvpn"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "${var.port}"
    to_port     = "${var.port}"
    protocol    = "${var.proto}"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
# Find the latest available amazon AMI
data "aws_ami" "amazon-linux-ami" {
  most_recent      = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["*amzn2-ami-hvm-*-x86_64-gp2"]
  }
  name_regex = "amzn2-ami-hvm-[.0-9]*-x86_64-gp2"
}
resource "aws_instance" "openvpn" {
  ami           = "${data.aws_ami.amazon-linux-ami.id}"
  instance_type = "${var.instance-type}"
  key_name = "${var.key-pair-name}"
  security_groups = ["${var.sg-name}"]
  root_block_device {
    volume_type = "gp2"
    volume_size = "30"
  }
  tags {
    Name = "${var.instance-name}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install docker 1>/dev/null",
      "sudo service docker start",
      "sudo docker run -v /opt/openvpn/etc:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u ${var.proto}://${aws_instance.openvpn.public_ip}:${var.port} ${var.custom-vpn-settings}",
      "sudo docker run -v /opt/openvpn/etc:/etc/openvpn --rm -it kylemanna/openvpn bash -c \"printf '\\n' | ovpn_initpki nopass\" ",
      "sudo docker run -v /opt/openvpn/etc:/etc/openvpn -d -p ${var.port}:1194/${var.proto} --cap-add=NET_ADMIN kylemanna/openvpn",
      "sudo docker run -v /opt/openvpn/etc:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full CLIENTSETTINGS nopass",
      "sudo docker run -v /opt/openvpn/etc:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient CLIENTSETTINGS > CLIENTSETTINGS.ovpn"
    ]
    on_failure = "fail"
    connection {
      user = "ec2-user"
      private_key = "${file("${var.ssh-private-key-path}")}"
    }
  }
}

output "get-client-settings" {
  value = [
    "Don't forget to get client .ovpn settings, execute this:",
    "ssh -i ~/.ssh/id_rsa.pub ec2-user@${aws_instance.openvpn.public_ip} cat CLIENTSETTINGS.ovpn > CLIENTSETTINGS.ovpn"
  ] 
}
