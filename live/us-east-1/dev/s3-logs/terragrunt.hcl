include {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id                = "vpc-mock"
    private_subnet_ids    = ["subnet-mock-1", "subnet-mock-2"]
    private_route_table_ids = ["rtb-mock-1", "rtb-mock-2"]
  }
}

locals {
  merged_tags = merge(
    read_terragrunt_config(find_in_parent_folders("root.hcl"))["locals"]["default_tags"],
    { Purpose = "mint-logs" }
  )
}

inputs = {
  bucket = "mint-poc-eks-logs-${get_env("AWS_ACCOUNT_ID", "")}" # Set via env or Terragrunt env
  tags = local.merged_tags
  # Add more S3 options as needed
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/s3-bucket/aws?version=5.9.1"
}
