include {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-mock"
  }
}

locals {
  merged_tags = merge(
    read_terragrunt_config(find_in_parent_folders("root.hcl"))["locals"]["default_tags"],
    {
      Name        = "poc-private-zone"
      Project     = "poc"
    }
  )
}

inputs = {
  name    = "poc.internal"
  comment = "Private zone for poc"
  records = {
    app_record = {
      name    = "app"
      type    = "A"
      ttl     = 300
      records = ["1.2.3.4"]
    }
  }
  vpc = {
    one = {
      vpc_id     = dependency.vpc.outputs.vpc_id
      vpc_region = "us-east-1"
    }
  }
  tags = local.merged_tags
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/route53/aws?version=6.1.1"
}
