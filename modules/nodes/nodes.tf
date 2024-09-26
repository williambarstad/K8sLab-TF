# IAM Role for EKS Worker Nodes
resource "aws_iam_role" "nodes" {
  name = "${var.env}-${var.eks_name}-eks-nodes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
}

# EKS Node Group (Worker Nodes)
resource "aws_eks_node_group" "general" {
  cluster_name    = var.eks_name
  version         = var.eks_version
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = [
    var.private_subnet_az1.id,
    var.private_subnet_az2.id
  ]

  capacity_type = local.capacity_type
  instance_types = [local.node_instance_type]

  scaling_config {
    desired_size = local.desired_cluster_size
    max_size     = local.max_cluster_size
    min_size     = local.min_cluster_size
  }

  update_config {
    max_unavailable = local.max_unavailable
  }

  labels = {
    role = local.node_group_name
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  tags = {
    Name = "eks-${local.node_group_name}-node-group"
  }
}
