include {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id            = "vpc-mock"
    public_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
  }

}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {}
}

locals {
  merged_tags = merge(
    read_terragrunt_config(find_in_parent_folders("root.hcl"))["locals"]["default_tags"],
    { Purpose = "mint-alb" }
  )
}

inputs = {
  name                   = "app-alb"
  vpc_id                 = dependency.vpc.outputs.vpc_id
  subnets                = dependency.vpc.outputs.public_subnet_ids
  load_balancer_type     = "application"
  internal               = true
  enable_deletion_protection = false

  # CRITICAL: Empty target_groups to avoid target_id error
  target_groups = {}

  # CRITICAL: Use http_listener instead of listeners map
  http_listener_enabled = true
  http_port             = 80

  tags = local.merged_tags
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/alb/aws?version=10.4.0"
}
