# Retrieve the current AWS account ID and user/role ARN
# This is used to get the caller identity, which provides the AWS account details.
data "aws_caller_identity" "current" {}

# Create an IAM role named "eks_admin" for administering EKS
# The "eks_admin" role allows EKS cluster administration by assuming this role.
resource "aws_iam_role" "eks_admin" {
  name = "${local.env}-${local.eks_name}-eks-admin"  # Name of the IAM role for the EKS admin.

  # Policy that allows this role to be assumed by the current AWS identity.
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = data.aws_caller_identity.current.arn  # The current AWS caller identity can assume this role.
        },
        Action = "sts:AssumeRole"  # Action allowing this role to be assumed by another entity.
      }
    ]
  })

  # Attach Amazon-managed policies to the EKS admin role for cluster and service-level access.
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",  # Grants permissions to manage EKS clusters.
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"   # Grants permissions to manage EKS service-related actions.
  ]
}

# Define an additional inline IAM policy for the EKS admin role
# This policy gives full administrative control over EKS, including passing roles to the EKS service.
resource "aws_iam_policy" "eks_admin" {
  name        = "AmazonEKSAdminPolicy"  # Name of the admin policy.
  description = "Admin policy"          # Description of what this policy does.
  
  # The policy allows all actions on the EKS service and IAM role passing for EKS.
  policy      = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",              # Allow all EKS actions.
        Action   = [
          "eks:*"                       # Wildcard action to allow all EKS-related API calls.
        ],
        Resource = "*"                  # Applies to all EKS resources.
      },
      {
        Effect   = "Allow",              # Allow IAM PassRole specifically for EKS service.
        Action   = "iam:PassRole",       # Permission to pass roles to EKS.
        Resource = "*",                  # Applies to all IAM roles.
        Condition = {
          StringEquals = {
            "iam:PassedToService": "eks.amazonaws.com"  # Condition: only pass roles to the EKS service.
          }
        }
      }
    ]
  })
}

# Attach the EKS admin policy to the "eks_admin" role
# This step ensures the "eks_admin" role receives the permissions from the custom EKS admin policy.
resource "aws_iam_role_policy_attachment" "eks_admin" {
  policy_arn = aws_iam_policy.eks_admin.arn  # The ARN of the EKS admin policy to attach.
  role       = aws_iam_role.eks_admin.name   # Attach the policy to the "eks_admin" role.
}

# Create an IAM user named "manager"
# The "manager" user will be used to assume the "eks_admin" role.
resource "aws_iam_user" "manager" {
  name = "manager"  # Name of the IAM user.
}

# Define a policy that allows the "manager" user to assume the "eks_admin" role
# This policy grants the "manager" user the ability to assume the EKS admin role, effectively delegating admin permissions.
resource "aws_iam_policy" "eks_assume_admin" {
  name        = "AmazonEKSAssumeAdminPolicy"  # Name of the assume role policy.
  description = "Manager policy"              # Description of the policy.
  
  # The policy allows the "manager" user to assume the EKS admin role.
  policy      = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",              # Allow the "AssumeRole" action.
        Action   = [
          "sts:AssumeRole"              # Permission to assume roles using STS.
        ],
        Resource = "${aws_iam_role.eks_admin.arn}"  # Can only assume the "eks_admin" role.
      }
    ]
  })
}

# Attach the "AmazonEKSAssumeAdminPolicy" to the "manager" user
# This ensures the "manager" user can assume the "eks_admin" role.
resource "aws_iam_user_policy_attachment" "manager" {
  policy_arn = aws_iam_policy.eks_assume_admin.arn  # Attach the "AssumeRole" policy to the user.
  user       = aws_iam_user.manager.name            # Attach it to the "manager" IAM user.
}

# Grant the "manager" user access to the EKS cluster with admin-level permissions
# The "manager" user will be added to the Kubernetes RBAC group "wjb-admin", typically an admin group.
resource "aws_eks_access_entry" "manager" {
  cluster_name       = aws_eks_cluster.eks.name     # The EKS cluster name.
  principal_arn      = aws_iam_user.manager.arn     # The ARN of the "manager" IAM user.
  
  # Assign the "manager" user to the Kubernetes "eks-admin" group, granting them admin permissions within the cluster.
  kubernetes_groups  = ["eks-admin"]
}

# # Update the Kubernetes configuration to use the new "manager" user credentials:
# #     aws eks update-kubeconfig --name <cluster-name> --region <region> --profile manager
