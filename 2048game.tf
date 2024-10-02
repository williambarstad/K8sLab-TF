# provider "kubernetes" {
#   host                   = aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority.0.data)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }

data "aws_ami" "eks_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-*"]  # Adjust the pattern to match the EKS AMI names
  }

  filter {
    name   = "owner-id"
    values = ["${var.account_id}"]  # This is the official AWS account ID for EKS AMIs
  }

  owners = ["${var.account_id}"]  # Amazon's AWS account that owns EKS AMIs
}


resource "kubernetes_deployment" "game_deployment" {
  metadata {
    name = "game-deployment"
    labels = {
      app = "game-2048"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "game-2048"
      }
    }

    template {
      metadata {
        labels = {
          app = "game-2048"
        }
      }

      spec {
        container {
          image = "kubespheredev/2048:latest"
          name  = "game-2048"
          port {
            container_port = 2048
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "game_service" {
  metadata {
    name = "game-service"
  }

  spec {
    selector = {
      app = "game-2048"
    }

    port {
      protocol    = "TCP"
      port        = 2048
      target_port = 2048
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "game_hpa" {
  metadata {
    name = "game-hpa"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.game_deployment.metadata[0].name
    }

    min_replicas = 2
    max_replicas = 10

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type = "Utilization"
          average_utilization = 50
        }
      }
    }
  }
}

resource "aws_launch_template" "eks_node_template" {
  name = "eks-node-template"

  image_id      = data.aws_ami.eks_ami.id
  instance_type = "t3.medium"

  key_name = var.key_name 

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "eks_node_group" {
  min_size         = 1
  max_size         = 10
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.eks_node_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = [
    aws_subnet.public_subnet_az1.id,
    aws_subnet.public_subnet_az2.id
  ]

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.eks_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

