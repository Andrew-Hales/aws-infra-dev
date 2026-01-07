include {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id                  = "vpc-mock"
    private_subnets         = ["subnet-mock-1", "subnet-mock-2"]
    private_route_table_ids = ["rtb-mock"]
  }
}

locals {
  merged_tags = merge(
    read_terragrunt_config(find_in_parent_folders("root.hcl"))["locals"]["default_tags"],
    {Purpose = "mint-vpc-endpoints"}
  )
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  endpoints = {
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
      security_group_ids  = []
      tags = local.merged_tags
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
      security_group_ids  = []
      tags = local.merged_tags
    }
    s3 = {
      service          = "s3"
      route_table_ids  = dependency.vpc.outputs.private_route_table_ids
      security_group_ids = []
      tags = local.merged_tags
    }
    secretsmanager = {
      service             = "secretsmanager"
      private_dns_enabled = true
      subnet_ids          = dependency.vpc.outputs.private_subnets
      security_group_ids  = []
      tags = local.merged_tags
    }
  }
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws//modules/vpc-endpoints?version=6.5.1"
}
