variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS Cluster"
  type        = string
  default     = "demoapp-cluster"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of Public subnet cidr"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}


variable "private_subnet_cidrs" {
  description = "List of Public subnet cidr"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}


variable "instance_type" {
  description = "Type of Worker node"
  type        = string
  default     = "t2.medium"
}

variable "desired_capacity" {
  description = "Number of Worker node"
  type        = number
  default     = 2
}