variable "public_subnet_cidr_az1" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr_az1" {
  default = "10.0.2.0/24"
}

variable "public_subnet_cidr_az2" {
  default = "10.0.3.0/24"
}

variable "private_subnet_cidr_az2" {
  default = "10.0.4.0/24"
}

# Public Subnet AZ1
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_az1
  availability_zone       = local.zone1
  map_public_ip_on_launch = true
  tags = {
    Name                                          = "${local.env}-public-${local.zone1}"
    "kubernetes.io/cluster/${local.eks_name}" = "owned"
    "kubernetes.io/role/elb"                      = "1"
  }
}

# Private Subnet AZ1
resource "aws_subnet" "private_subnet_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_az1
  availability_zone = local.zone1
  tags = {
    Name                                          = "${local.env}-private-${local.zone1}"
    "kubernetes.io/cluster/${local.eks_name}" = "owned"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

# Public Subnet AZ2
resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_az2
  availability_zone       = local.zone2
  map_public_ip_on_launch = true
  tags = {
    Name = "${local.env}-public-${local.zone2}"
  }
}

# Private Subnet AZ2
resource "aws_subnet" "private_subnet_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_az2
  availability_zone = local.zone2
  tags = {
    Name = "${local.env}-private-${local.zone2}"
  }
}
