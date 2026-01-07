include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  merged_tags = merge(
    read_terragrunt_config(find_in_parent_folders("root.hcl"))["locals"]["default_tags"],
    {Purpose = "mint-vpc"}
  )
}

inputs = {
  azs                  = ["us-east-1a", "us-east-1b"]
  cidr                 = "10.0.0.0/20"
  enable_dns_hostnames = true
  enable_nat_gateway   = true
  # single_nat_gateway = true if we want just one nat gateway in dev
  enable_dns_support   = true
  map_public_ip_on_launch = true
  name                 = "mint-poc-eks-openvpn"
  private_subnets      = ["10.0.10.0/24", "10.0.11.0/24"]
  public_subnets       = ["10.0.0.0/24", "10.0.1.0/24"]
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
  tags = local.merged_tags
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws?version=6.5.1"
}
