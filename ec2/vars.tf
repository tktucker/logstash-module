variable "region" {
  description = "region to configure aws provider"
}

variable "vpc_id" {
  description = "VPC ID to target"
}

variable "ami_id" {
  description = "Amazon EC2 AMI ID to use"
}

variable "logstash_server_port" {
  description = "Establishing the TCP port used by Logstash"
}

variable "server_instance_type" {
  description = "The default Amazon EC2 Instance size"
}
variable "subnet_id" {
  description = "The public subnet ID the instance should reside in"
}

