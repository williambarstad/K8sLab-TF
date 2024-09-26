# main.tf

# VPC and related resources
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${local.env}-main"
  }
}

# Public Subnet AZ1
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_az1
  availability_zone       = local.azone1
  map_public_ip_on_launch = true
  tags = {
    Name                                      = "${local.env}-public-${local.azone1}"
    "kubernetes.io/cluster/${local.eks_name}" = "owned"
    "kubernetes.io/role/elb"                  = "1"
  }
}

# Private Subnet AZ1
resource "aws_subnet" "private_subnet_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_az1
  availability_zone = local.azone1
  tags = {
    Name                                      = "${local.env}-private-${local.azone1}"
    "kubernetes.io/cluster/${local.eks_name}" = "owned"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}

# Public Subnet AZ2
resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_az2
  availability_zone       = local.azone2
  map_public_ip_on_launch = true
  tags = {
    Name = "${local.env}-public-${local.azone2}"
  }
}

# Private Subnet AZ2
resource "aws_subnet" "private_subnet_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_az2
  availability_zone = local.azone2
  tags = {
    Name = "${local.env}-private-${local.azone2}"
  }
}

# Internet Gateway
# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.main.id
#   tags = {
#     Name = "${local.env}-igw"
#   }
# }

# resource "aws_eip" "nat" {
#   domain = "vpc"

#   tags = {
#     Name = "${local.env}-nat"
#   }
# }

# resource "aws_nat_gateway" "nat" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public_subnet_az1.id

#   tags = {
#     Name = "${local.env}-nat"
#   }

#   depends_on = [
#     aws_internet_gateway.igw
#   ]
# }

# # Route Tables
# resource "aws_route_table" "private_rt" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat.id
#   }

#   tags = {
#     Name = "${local.env}-private"
#   }
# }

# # Route Table for Public Subnets
# resource "aws_route_table" "public_rt" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }

#   tags = {
#     Name = "${local.env}-public"
#   }
# }

# resource "aws_route_table_association" "private_azone1" {
#   subnet_id      = aws_subnet.private_subnet_az1.id
#   route_table_id = aws_route_table.private_rt.id
# }

# resource "aws_route_table_association" "private_azone2" {
#   subnet_id      = aws_subnet.private_subnet_az2.id
#   route_table_id = aws_route_table.private_rt.id
# }

# resource "aws_route_table_association" "public_azone1" {
#   subnet_id      = aws_subnet.public_subnet_az1.id
#   route_table_id = aws_route_table.public_rt.id
# }

# resource "aws_route_table_association" "public_azone2" {
#   subnet_id      = aws_subnet.public_subnet_az2.id
#   route_table_id = aws_route_table.public_rt.id
# }

# Load the NAT gateway module
module "nat" {
  source = "./modules/nat"
  
  # Pass the required variables
  vpc_id = var.vpc_cidr
  env = local.env
  public_subnet_az1 = var.public_subnet_cidr_az1.id

  # Deploy the NAT module if the flag is set to true
  count = local.deploy_nat_module ? 1 : 0
}

# Load the EKS cluster module
module "eks" {
  source = "./modules/eks"

  env       = local.env       
  eks_name  = local.eks_name  
  eks_version = local.eks_version
  public_subnet_az1 = var.public_subnet_cidr_az1.id 
  private_subnet_az2 = var.private_subnet_cidr_az2.id

  # Deploy the EKS module if the flag is set to true
  count = local.deploy_eks_module ? 1 : 0  
}

# Load the EKS nodes module
module "nodes" {
  source = "./modules/nodes"

  # Pass the required variables
  env = local.env
  eks_name = local.eks_name
  eks_version = local.eks_version
  public_subnet_az1 = var.public_subnet_cidr_az1.id
  private_subnet_az2 = var.private_subnet_cidr_az2.id

  # Deploy the nodes module if the flag is set to true
  count = local.deploy_nodes_module ? 1 : 0
}

# Load the roles module
# module "roles" {
#   source = "./modules/roles"

#   # Deploy the roles module if the flag is set to true
#   count = local.deploy_roles_module ? 1 : 0
# }

# # Load the users module
# module "users" {
#   source = "./modules/users"

#   # Deploy the users module if the flag is set to true
#   count = local.deploy_users_module ? 1 : 0
# }
