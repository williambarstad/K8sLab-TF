locals {
  env    = "staging"
  region = "us-west-2"
  zone1  = "us-west-2a"
  zone2  = "us-west-2b"
  eks_name = "eks-${local.env}"
  eks_version = "1.30"
}
