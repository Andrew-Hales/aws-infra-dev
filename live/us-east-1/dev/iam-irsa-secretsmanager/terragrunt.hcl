include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "eks" {
  config_path                          = "../eks"
  mock_outputs                         = {
    cluster_name       = "testpoc-eks-cluster"
    oidc_provider_arn  = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
    oidc_provider      = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

locals {
  merged_tags = merge(
    read_terragrunt_config(find_in_parent_folders("root.hcl"))["locals"]["default_tags"],
    { Purpose = "test-irsa-secretsmanager" }
  )
}

inputs = {
  role_name   = "test-irsa-secretsmanager"
  tags        = local.merged_tags

  attach_policy_statements = [
    {
      effect  = "Allow"
      actions = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
    }
  ]

  oidc_providers = [
    {
      provider_arn             = dependency.eks.outputs.oidc_provider_arn
      namespace_service_accounts = ["default:secrets-access-sa"]
    }
  ]
}

terraform {
  source = "tfr:///terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks?version=5.6.0"
}
