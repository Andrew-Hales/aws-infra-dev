include {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id            = "vpc-mock"
    public_subnet_ids  = ["subnet-mock-1", "subnet-mock-2"]
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
  }
}

locals {
  merged_tags = merge(
    read_terragrunt_config(find_in_parent_folders("root.hcl"))["locals"]["default_tags"],
    {Purpose = "mint-eks-cluster"}
  )
}

inputs = {
  name    = "mint-poc-eks-cluster"
  kubernetes_version = "1.33"
  vpc_id          = dependency.vpc.outputs.vpc_id
  control_plane_subnet_ids = dependency.vpc.outputs.private_subnets
  subnet_ids      = dependency.vpc.outputs.private_subnets
  enable_irsa     = true
  endpoint_private_access = true
  endpoint_public_access  = false
  manage_aws_auth_configmap = true

  addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    vpc-cni                = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }
  }

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.medium"]
      key_name       = "mint-eks-key"
      tags           = local.merged_tags
    }
  }
  tags = local.merged_tags
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/eks/aws?version=21.10.1"
}
