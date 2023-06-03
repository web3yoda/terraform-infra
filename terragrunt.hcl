locals {
  account_vars    = yamldecode(file(find_in_parent_folders("account.yaml")))
  region_vars     = yamldecode(file(find_in_parent_folders("region.yaml")))
  env_vars        = yamldecode(file(find_in_parent_folders("env.yaml")))
  account_name    = local.account_vars.account_name
  account_id      = local.account_vars.aws_account_id
  account_profile = lookup(local.account_vars, "aws_account_profile", "default")
  aws_region      = local.region_vars.aws_region
  bucket_prefix   = "w3m"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

terraform { 
  required_providers { 
    aws = { 
      source = "hashicorp/aws"
      version = "5.1.0" 
    } 
  } 
} 

provider "aws" {
  region = "${local.aws_region}"
  allowed_account_ids = ["${local.account_id}"]
}

EOF
}

remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "${local.bucket_prefix}-${local.account_name}-${local.aws_region}-tfstate"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    dynamodb_table = "terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}


inputs = merge(
  local.account_vars,
  local.region_vars,
  local.env_vars,
)
# test
