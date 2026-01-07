include {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-mock"
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
    public_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
    availability_zones = ["us-east-1a", "us-east-1b"]
    private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  }
}

locals {
  merged_tags = merge(
    read_terragrunt_config(find_in_parent_folders("root.hcl"))["locals"]["default_tags"],
    { Purpose = "mint-airflow-efs" }
  )
}

inputs = {
  name = "mint-efs"
  creation_token = "mint-efs-token"
  encrypted = true
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  vpc_id = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnet_ids
  security_group_description = "EFS access"
  security_group_vpc_id = dependency.vpc.outputs.vpc_id
  security_group_rules = [
    {
      type        = "ingress"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = dependency.vpc.outputs.private_subnet_cidrs # Dynamically use private subnet CIDRs
      description = "NFS access"
    },
    {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "All traffic"
    }
  ]
  tags = local.merged_tags
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/efs/aws?version=2.0.0"
}
