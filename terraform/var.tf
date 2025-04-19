variable "region" {
    description = "The AWS region to deploy the resources in."
    type        = string
    default     = "ap-south-1"
}

variable "cluster_name" {
    description = "The name of the EKS cluster."
    type        = string
    default     = "demoapp-cluster"
  
}

variable "vpc_cidr" {
    description = "value of the VPC CIDR block."
    type        = string
    default = "10.0.0.0/16"
  
}

variable "public_subnet_cidrs" {
    description = "value of the public subnet CIDR blocks."
    type        = list(string)
    default = [ "10.0.1.0/24", "10.0.2.0/24"]
  
}

variable "private_subnet_cidrs" {
    description = "value of the private subnet CIDR blocks."
    type        = list(string)
    default = [ "10.0.3.0/24", "10.0.4.0/24" ]
  
}


variable "instance_type" {
    description = "The instance type for the EC2 instances."
    type        = string
    default     = "t2.medium"
}


variable "desired_capacity" {
    description = "The desired capacity of the EC2 instances."
    type        = number
    default     = 2
  
}