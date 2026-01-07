locals {
  project_name = "mint-poc-eks-openvpn"
  default_tags = {
    Environment = "dev"
    ManagedBy   = "terragrunt"
    Project     = "mint"
  }
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "mint-terraform-state-bucket-dev"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "mint-terraform-lock-table"
    s3_bucket_tags = local.default_tags
    skip_bucket_versioning = false
  }
}

inputs = {
  project_name = local.project_name
  tags         = local.default_tags
}
