terraform {
  required_providers {
    databricks = {
      source  = "databrickslabs/databricks"
      version = "0.4.5"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "3.72.0"
    }
  }
}

provider "aws" {
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "terraform_remote_state" "db" {
  backend = "local"

  config = {
    path = "../provision/terraform.tfstate"
  }
}

provider "databricks" {
  host  = data.terraform_remote_state.db.outputs.databricks_host
  token = data.terraform_remote_state.db.outputs.databricks_token
}

locals {
  prefix = data.terraform_remote_state.db.outputs.databricks_workspace_name
}

output "databricks_host" {
  value = data.terraform_remote_state.db.outputs.databricks_host
}
