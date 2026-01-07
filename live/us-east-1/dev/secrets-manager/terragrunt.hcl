include {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc_endpoints" {
  config_path = "../vpc-endpoints"
  mock_outputs = {
    endpoints = {
      secretsmanager = {
        id = "vpce-mocksecretsmanagerid"
      }
    }
  }
}

locals {
  merged_tags = merge(
    read_terragrunt_config(find_in_parent_folders("root.hcl"))["locals"]["default_tags"],
    { Purpose = "mint-secrets-manager" }
  )
}

inputs = {
  name        = "mint-secrets-manager"
  description = "Secrets for Mint EKS/OpenVPN PoC"
  recovery_window_in_days = 7
  tags        = local.merged_tags
  # Add secret_string or secret_binary as needed
  secret_string = jsonencode({
    example_key = "example_value"
  })
  resource_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "DenyAllExceptVPCE",
        Effect = "Deny",
        Principal = "*",
        Action = "secretsmanager:GetSecretValue",
        Resource = "*",
        Condition = {
          StringNotEquals = {
            "aws:sourceVpce" = dependency.vpc_endpoints.outputs.endpoints["secretsmanager"].id
          }
        }
      },
      {
        Sid = "AllowEKSIRSA",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_EKS_IRSA_ROLE_NAME"
        },
        Action = "secretsmanager:GetSecretValue",
        Resource = "*"
      }
    ]
  })
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/secrets-manager/aws?version=2.0.1"
}
