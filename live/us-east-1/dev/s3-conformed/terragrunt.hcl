include {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc-endpoints"
  mock_outputs = {
    endpoints = {
      s3 = {
        id = "vpce-mockendpointid"
      }
    }
  }
}

locals {
  merged_tags = merge(
    read_terragrunt_config(find_in_parent_folders("root.hcl"))["locals"]["default_tags"],
    { Purpose = "mint-conformed" }
  )
}

inputs = {
  bucket = "mint-poc-eks-conformed"
  tags   = local.merged_tags
  bucket_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "DenyAllExceptVPCE",
        Effect = "Deny",
        Principal = "*",
        Action = "s3:*",
        Resource = [
          "arn:aws:s3:::mint-poc-eks-conformed",
          "arn:aws:s3:::mint-poc-eks-conformed/*"
        ],
        Condition = {
          StringNotEquals = {
            "aws:sourceVpce" = dependency.vpc.outputs.endpoints["s3"].id
          }
        }
      }
    ]
  })
  # Add more S3 options as needed
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/s3-bucket/aws?version=5.9.1"
}
