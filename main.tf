provider "aws" {
  region = var.region
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
resource "aws_subnet" "public_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = "${var.availability_zones[count.index]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnets" {
  count     = 2
  vpc_id    = aws_vpc.my_vpc.id
  cidr_block = "10.0.${count.index + 2}.0/24"
  availability_zone = "${var.availability_zones[count.index]}"
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
  version = "~> 19.0"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.27"

  vpc_id     = aws_vpc.my_vpc.id
  subnet_ids = aws_subnet.private_subnets.id

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Managed Node Group
module "eks_eks-managed-node-group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "19.17.2"
  cluster_name    = module.eks.cluster_id
  name = "managed-ng"
  instance_type = "t2.micro"
  min_size     = 1
  max_size     = 2
  desired_size = 2
}

# Unmanaged Node Group
module "eks_self-managed-node-group" {
  source  = "terraform-aws-modules/eks/aws//modules/self-managed-node-group"
  version = "19.17.2"
  cluster_name    = module.eks.cluster_id
  name = "unmanaged-ng"
  instance_type = "t2.micro"
  min_size     = 1
  max_size     = 2
  desired_size = 2
}


