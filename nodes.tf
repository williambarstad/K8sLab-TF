# IAM Role for EKS Worker Nodes
resource "aws_iam_role" "nodes" {
  name = "${var.env}-${local.eks_name}-eks-nodes"

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
  cluster_name    = aws_eks_cluster.eks.name
  version         = var.eks_version
  node_group_name = "general"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = [
    aws_subnet.private_subnet_az1.id,
    aws_subnet.private_subnet_az2.id
  ]

  capacity_type = var.capacity_type
  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.desired_cluster_size
    max_size     = var.max_cluster_size
    min_size     = var.min_cluster_size
  }

  update_config {
    max_unavailable = var.max_unavailable
  }
  
  labels = {
    role = aws_eks_cluster.eks.name
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  tags = {
    Name = aws_eks_cluster.eks.name
  }
}
