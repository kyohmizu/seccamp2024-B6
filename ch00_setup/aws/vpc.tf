module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "vpc-${var.env}"
  cidr = var.vpc_cidr

  azs            = ["${var.region}a"]
  public_subnets = [var.vpc_subnet]

  map_public_ip_on_launch = true

  tags = local.tags
}
