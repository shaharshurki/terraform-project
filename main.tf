provider "aws" {
  region = "us-west-2" # Replace with your desired AWS region
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "my-vpc"
  }
}

# Create two public and two private subnets across two availability zones
resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = "us-west-2a" # Adjust availability zones
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  count     = 2
  vpc_id    = aws_vpc.my_vpc.id
  cidr_block = "10.0.${count.index + 2}.0/24"
  availability_zone = "us-west-2b" # Adjust availability zones
  tags = {
    Name = "private-subnet-${count.index}"
  }
}

# Create an internet gateway and attach it to the VPC for public subnet access
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route" "internet_route" {
  route_table_id         = aws_vpc.my_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

# Create an EKS cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name = "my-cluster"
  cluster_version = "1.21"

  subnets = concat(aws_subnet.public_subnet[*].id, aws_subnet.private_subnet[*].id)

  vpc_id = aws_vpc.my_vpc.id

  node_groups = {
    managed_node_group = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t2.micro"
    }
    unmanaged_node_group = {
      desired_capacity = 1
      max_capacity     = 2
      min_capacity     = 1
      instance_type    = "t3.micro"
    }
  }
}

# Add an EKS add-on (for example, the Kubernetes dashboard)
resource "kubernetes_namespace" "dashboard" {
  metadata {
    name = "kube-system"
  }
}

resource "helm_release" "dashboard" {
  name       = "kubernetes-dashboard"
  namespace  = kubernetes_namespace.dashboard.metadata[0].name
  repository = "https://charts.helm.sh/stable"
  chart      = "kubernetes-dashboard"
  version    = "4.2.3"
}
