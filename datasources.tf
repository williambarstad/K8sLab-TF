data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["${local.ami_name}"]
  }
}

