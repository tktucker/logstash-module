  
provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {}
  #required_version = ">= 0.12.17"
}

# Create EC2 Logstash Instance

resource "aws_security_group" "server_sg" {
  vpc_id = var.vpc_id

  # SSH ingress access for provisioning
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access for provisioning"
  }

  ingress {
    from_port   = var.logstash_server_port
    to_port     = var.logstash_server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to X servers"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "logstash" {
  ami                         = var.ami_id
  instance_type               = var.server_instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = ["${aws_security_group.server_sg.id}"]
  key_name                    = "logstash-test"
  #key_name                    = "${aws_key_pair.aws_keypair.key_name}"
  associate_public_ip_address = true
  count                       = 1

  tags = {
    Name = "logstash"
  }
  provisioner "remote-exec" {
    # Install Python for Ansible
    inline = ["sudo yum -y install telnet"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("/Users/ttucker/Downloads/logstash-test.pem")}"
      host = "${self.public_ip}"
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ec2-user -i \"${self.public_ip},\" --private-key /Users/ttucker/Downloads/logstash-test.pem -T 300 provision.yml"
  }
}


