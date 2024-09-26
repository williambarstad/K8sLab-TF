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
