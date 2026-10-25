variable "aws_region" {
  description = "AWS region for the monitoring server."
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair in aws_region."
  type        = string
}

variable "ssh_ingress_cidrs" {
  description = "Public IPv4 CIDRs allowed to SSH to the monitoring server (one /32 per access location)."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for the monitoring server."
  type        = string
  default     = "t3.small"
}
