include {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-mock"
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
    availability_zones = ["us-east-1a", "us-east-1b"]
    database_subnet_group = "mock-db-subnet-group"
    database_subnet_group_name = "mock-db-subnet-group"
    database_subnet_group_id = "mock-db-subnet-group"
    private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  }
}

locals {
  merged_tags = merge(
    read_terragrunt_config(find_in_parent_folders("root.hcl"))["locals"]["default_tags"],
    { Purpose = "mint-postgres" }
  )
}

inputs = {
  identifier = "mint-postgres-db"
  engine = "postgres"
  engine_version = "18.1"
  family = "postgres18"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  max_allocated_storage = 100
  db_name = "mintdb"
  username = "mintadmin"
  password = "changeme123!" # Replace with a secure value or use secrets manager
  port = 5432
  vpc_security_group_ids = [] # Optionally reference a security group
  subnet_ids = dependency.vpc.outputs.private_subnet_ids
  publicly_accessible = false
  skip_final_snapshot = true
  tags = local.merged_tags
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/rds/aws?version=7.0.0"
}
