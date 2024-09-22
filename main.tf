# main.tf

# IAM Role for EKS Worker Nodes
# resource "aws_iam_role" "eks_node_role" {
#   name = "eks-node-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })

#   managed_policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
#     "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
#     "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   ]
# }



# Security Group for ALB
# resource "aws_security_group" "alb_sg" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "alb-sg"
#   }
# }

# # ALB
# resource "aws_lb" "main_alb" {
#   name               = "main-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb_sg.id]
#   subnets            = [aws_subnet.public_subnet_az1.id]

#   tags = {
#     Name = "main-alb"
#   }
# }

# # Target Group for Kubernetes Nodes
# resource "aws_lb_target_group" "k8s_tg" {
#   name     = "k8s-target-group"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main.id

#   health_check {
#     path                = "/"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 5
#     unhealthy_threshold = 2
#   }

#   tags = {
#     Name = "k8s-target-group"
#   }
# }

# # ALB Listener
# resource "aws_lb_listener" "alb_listener" {
#   load_balancer_arn = aws_lb.main_alb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.k8s_tg.arn
#   }
# }

# # Security Group for Kubernetes Nodes
# resource "aws_security_group" "k8s_sg" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = [var.vpc_cidr]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "k8s-sg"
#   }
# }

# # Launch EC2 Instances for Kubernetes Nodes
# resource "aws_instance" "k8s_node_az1" {
#   ami                    = "ami-xxxxxxxx"  # Replace with actual Kubernetes AMI
#   instance_type          = "t3.medium"
#   subnet_id              = aws_subnet.private_subnet_az1.id
#   security_groups        = [aws_security_group.k8s_sg.id]

#   tags = {
#     Name = "k8s-node-az1"
#   }
# }

# resource "aws_instance" "k8s_node_az2" {
#   ami                    = "ami-xxxxxxxx"  # Replace with actual Kubernetes AMI
#   instance_type          = "t3.medium"
#   subnet_id              = aws_subnet.private_subnet_az2.id
#   security_groups        = [aws_security_group.k8s_sg.id]

#   tags = {
#     Name = "k8s-node-az2"
#   }
# }
