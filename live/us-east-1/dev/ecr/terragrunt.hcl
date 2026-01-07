include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  merged_tags = merge(
    read_terragrunt_config(find_in_parent_folders("root.hcl"))["locals"]["default_tags"],
    { Name = "mint-ecr" }
  )
}

inputs = {
  repository_name                 = "mint-poc-eks-openvpn-persistent-ecr"
  repository_image_tag_mutability = "MUTABLE"
  repository_image_scan_on_push   = true
  create_lifecycle_policy         = false
  attach_repository_policy        = false
  tags = local.merged_tags
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/ecr/aws?version=3.1.0"
}