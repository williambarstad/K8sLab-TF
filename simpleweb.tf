# provider "kubernetes" {
#   host                   = aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority.0.data)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }

# resource "kubernetes_horizontal_pod_autoscaler_v2" "simple_web_hpa" {
#   metadata {
#     name = "simple-web-hpa"
#     namespace = "default"
#   }

#   spec {
#     min_replicas = 2
#     max_replicas = 10

#     scale_target_ref {
#       api_version = "apps/v1"
#       kind        = "Deployment"
#       name        = kubernetes_deployment.simple_web_deployment.metadata[0].name
#     }

#     metric {
#       type = "Resource"
#       resource {
#         name = "cpu"
#         target {
#           type = "Utilization"
#           average_utilization = 50
#         }
#       }
#     }
#   }
# }

