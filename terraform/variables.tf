variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-01a00762f46d584a1"
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  default     = "m7i-flex.large"
}
