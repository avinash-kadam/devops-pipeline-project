variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for all resource names"
  type        = string
  default     = "devops-demo"
}

variable "environment" {
  description = "Environment tag (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID — check AWS console for the latest in your region"
  type        = string
  # us-east-1 AMI as of mid-2024 — update if you're in a different region
  default = "ami-0c02fb55956c7d316"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
  # Create in AWS Console: EC2 > Key Pairs > Create, then reference the name here
}

variable "allowed_ssh_cidr" {
  description = "Your IP in CIDR notation. Find it at https://whatismyip.com"
  type        = string
  default     = "0.0.0.0/0"   # tighten this to your IP in production
}
