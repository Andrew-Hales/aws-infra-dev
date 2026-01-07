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
    { Name = "admin-ssh-sg" }
  )
}

inputs = {
  name        = "security-group-admin"
  description = "Admin SSH access security group"
  vpc_id      = dependency.vpc.outputs.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access from admin CIDR"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  tags = local.merged_tags
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/security-group/aws?version=5.3.1"
}
