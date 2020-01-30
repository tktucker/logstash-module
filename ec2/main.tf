  
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
    inline = ["sudo yum -y install git"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("~/.ssh/logstash-test.pem")}"
      host = "${self.public_ip}"
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ec2-user -i \"${self.public_ip},\" --private-key ~/.ssh/logstash-test.pem -T 300 provision.yml"
  }
}


# build the CloudWatch auto-recovery alarm and recovery action
resource "aws_cloudwatch_metric_alarm" "logstash" {
  alarm_name         = "instance-autorecovery"
  namespace          = "AWS/EC2"
  evaluation_periods = "2"
  period             = "60"
  alarm_description  = "This metric auto recovers EC2 instances"

  alarm_actions = ["arn:aws:automate:var.region:ec2:recover"]
  #alarm_actions = ["arn:aws:automate:${var.region}:ec2:recover"]

  statistic           = "Minimum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0.0"
  metric_name         = "StatusCheckFailed_System"


}


