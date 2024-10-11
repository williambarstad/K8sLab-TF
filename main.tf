# main.tf

# VPC and related resources
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.env}-main"
  }
}

# CloudWatch log group for VPC flow logs
resource "aws_cloudwatch_log_group" "flow_logs_group" {
  name              = "${var.env}-flow-logs-group"
  retention_in_days = 14  # Set the retention as needed
}

# IAM role for VPC flow logs
resource "aws_iam_role" "flow_logs_role" {
  name = "${var.env}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for CloudWatch Logs
resource "aws_iam_role_policy" "flow_logs_policy" {
  name   = "${var.env}-flow-logs-policy"
  role   = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.flow_logs_group.arn}:*"
      }
    ]
  })
}

# VPC flow logs sending to CloudWatch Logs
resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_cloudwatch_log_group.flow_logs_group.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"  # Options: ACCEPT, REJECT, or ALL
  vpc_id               = aws_vpc.main.id

  iam_role_arn = aws_iam_role.flow_logs_role.arn
}

# Subnets
# Public Subnet AZ1
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_az1
  availability_zone       = var.azone1
  map_public_ip_on_launch = true
  tags = {
    Name                                      = "${var.env}-public-${var.azone1}"
    "kubernetes.io/cluster/${local.eks_name}" = "owned"
    "kubernetes.io/role/elb"                  = "1"
  }
}

# Private Subnet AZ1
resource "aws_subnet" "private_subnet_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_az1
  availability_zone = var.azone1
  tags = {
    Name                                      = "${var.env}-private-${var.azone1}"
    "kubernetes.io/cluster/${local.eks_name}" = "owned"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}

# Public Subnet AZ2
resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_az2
  availability_zone       = var.azone2
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.env}-public-${var.azone2}"
  }
}

# Private Subnet AZ2
resource "aws_subnet" "private_subnet_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_az2
  availability_zone = var.azone2
  tags = {
    Name = "${var.env}-private-${var.azone2}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.env}-nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_az1.id

  tags = {
    Name = "${var.env}-nat"
  }

  depends_on = [
    aws_internet_gateway.igw
  ]
}

# Route Tables
# Route Table for Private Subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.env}-private"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env}-public"
  }
}

resource "aws_route_table_association" "private_azone1" {
  subnet_id      = aws_subnet.private_subnet_az1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_azone2" {
  subnet_id      = aws_subnet.private_subnet_az2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "public_azone1" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_azone2" {
  subnet_id      = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_rt.id
}


# Load the roles module
# module "roles" {
#   source = "./modules/roles"

#   # Deploy the roles module if the flag is set to true
#   count = var.deploy_roles_module ? 1 : 0
# }

# # Load the users module
# module "users" {
#   source = "./modules/users"

#   # Deploy the users module if the flag is set to true
#   count = var.deploy_users_module ? 1 : 0
# }
