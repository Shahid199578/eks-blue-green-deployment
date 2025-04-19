provider "aws" {
  region = "var.region"
  
}

data "aws_availability_zones" "available" {}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# public Subnet

resource "aws_subnet" "public" {
  count            = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.cluster_name}-public-subnet-${count.index + 1}"
  }
}

# private Subnet

resource "aws_subnet" "private" {
  count            = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.cluster_name}-private-subnet-${count.index + 1}"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}


# Create a Route Table for the public subnet

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "${var.cluster_name}-public-route-table"
    }
  
}



# Associate the public route table with the public subnets
resource "aws_route_table_association" "public_asoc" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}



# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = vpc
}

# Nat Gateway

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.cluster_name}-nat-gateway"
  }
}

# Create a Route Table for the private subnets

resource "aws_route_table" "privat" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }
    tags = {
        Name = "${var.cluster_name}-private-route-table"
    }
  
}

# Associate the private route table with the private subnets
resource "aws_route_table_association" "private_asoc" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.privat.id
}



# IAM Role for EKS Cluster

resource "aws_iam_role" "eks_cluster_role" {
    name = "${var.cluster_name}-eks-cluster-role"
    assume_role_policy = jsondecode({
        Version = "2012-10-17",
        Statement = [
            {
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = {
                    Service = "eks.amazonaws.com"
                }
            }
        ]
    })
    
    tags = {
        Name = "${var.cluster_name}-eks-cluster-role"
    }
  
}

# Attach the AmazonEKSClusterPolicy to the IAM Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    role       = aws_iam_role.eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Cluster

resource "aws_eks_cluster" "demo" {
    name     = var.cluster_name
    role_arn = aws_iam_role.eks_cluster_role.arn

    vpc_config {
        subnet_ids = concat(
            aws_subnet.public[*].id,
            aws_subnet.private[*].id
        )
    }

    depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
  
}

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_group_role" {
    name = "${var.cluster_name}-eks-node-group-role"
    assume_role_policy = jsondecode({
        Version = "2012-10-17",
        Statement = [
            {
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })
    
    tags = {
        Name = "${var.cluster_name}-eks-node-group-role"
    }
  
}


# Attach the AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy and AmazonEC2ContainerRegistryReadOnly policies to the IAM Role

resource "aws_iam_role_policy_attachment" "eks_node_group_policy" {
    for_each = toset([
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policyAmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policyAmazonEC2ContainerRegistryReadOnly"
    ])
    role       = aws_iam_role.eks_node_group_role.name
    policy_arn = each.value
}

# EKS Node Group

resource "aws_eks_node_group" "node_group" {
    cluster_name    = aws_eks_cluster.demo.name
    node_group_name = "${var.cluster_name}-node-group"
    node_role_arn   = aws_iam_role.eks_node_group_role.arn
    subnet_ids      = aws_subnet.private[*].id

    scaling_config {
        desired_size = var.desired_capacity
        max_size     = var.desired_capacity + 1
        min_size     = 1
    }
    instance_types = [var.instance_type]
    depends_on = [aws_iam_role_policy_attachment.eks_node_group_policy]
  
}