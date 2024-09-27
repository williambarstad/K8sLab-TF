# # Create an IAM user named "developer"
# # This user will be used to interact with the EKS cluster.
# resource "aws_iam_user" "developer" {
#   name = "developer"  # The name of the IAM user.
# }

# # Define an IAM policy specific to EKS for the developer user
# # This policy grants the developer user permission to describe and list EKS clusters.
# resource "aws_iam_policy" "developer_eks" {
#   name        = "AmazonEKSDeveloperPolicy"  # The name of the policy.
#   description = "Developer policy"          # A brief description of the policy.
  
#   # The policy grants the developer permissions on the EKS service.
#   # It allows the user to describe clusters and list clusters.
#   policy      = jsonencode({
#     Version   = "2012-10-17",  # Policy version format.
#     Statement = [
#       {
#         Effect   = "Allow",    # Allows the actions defined below.
#         Action   = [
#             "eks:DescribeCluster",  # Allows describing EKS clusters.
#             "eks:ListClusters"      # Allows listing EKS clusters.
#         ],
#         Resource = "*"  # Applies to all EKS clusters within the account.
#       }
#     ]
#   })
# }

# # Attach the above policy to the developer user
# # This step ensures that the IAM user "developer" has the permissions defined in the AmazonEKSDeveloperPolicy.
# resource "aws_iam_policy_attachment" "developer_eks" {
#     name       = "developer-eks-policy-attachment"  # Name of the policy attachment.
#     users      = [aws_iam_user.developer.name]      # Attach the policy to the "developer" IAM user.
#     policy_arn = aws_iam_policy.developer_eks.arn   # The ARN of the EKS policy to attach.
# }

# # Grant the developer user access to the EKS cluster
# # This resource integrates the IAM user with Kubernetes by adding the user to the EKS access control list (ACL).
# resource "aws_eks_access_entry" "developer" {
#   cluster_name       = aws_eks_cluster.eks.name    # The name of the EKS cluster to grant access to.
#   principal_arn      = aws_iam_user.developer.arn  # The ARN of the IAM user (developer).
  
#   # Kubernetes groups define access levels within Kubernetes itself.
#   # This user is added to the "eks-viewer" Kubernetes group, which typically has read-only permissions.
#   kubernetes_groups  = ["eks-viewer"]
# }

# # Update the Kubernetes configuration to use the new "developer" user credentials:
# #   aws eks update-kubeconfig --name <cluster-name> --region <region> --profile developer