data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eks_admin" {
  name = "${local.env}-${local.eks_name}-eks-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = data.aws_caller_identity.current.arn
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  ]
}

resource "aws_iam_policy" "eks_admin" {
  name        = "AmazonEKSAdminPolicy"
  description = "Admin policy"
  policy      = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
            "eks:*"
            ],
        Resource = "*"
      },
      {
        "Effect": "Allow",
        "Action": "iam:PassRole",
        "Resource": "*",
        "Condition": {
          "StringEquals": {
            "iam:PassedToService": "eks.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin" {
  policy_arn = aws_iam_policy.eks_admin.arn
  role       = aws_iam_role.eks_admin.name
}

resource "aws_iam_user" "manager" {
  name = "manager"
}

resource "aws_iam_policy" "eks_assume_admin" {
  name        = "AmazonEKSAssumeAdminPolicy"
  description = "Manager policy"
  policy      = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
            "sts:AssumeRole"
            ],
        Resource = "${aws_iam_role.eks_admin.arn}"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "manager" {
  policy_arn = aws_iam_policy.eks_assume_admin.arn
  user       = aws_iam_user.manager.name
}

resource "aws_eks_access_entry" "manager" {
  cluster_name = aws_eks_cluster.eks.name
  principal_arn = aws_iam_user.manager.arn
  kubernetes_groups = ["wjb-admin"]
}
