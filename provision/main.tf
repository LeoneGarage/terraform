terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.39.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.14.0"
    }
  }
}

provider "aws" {
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  profile = var.aws_profile
}

// initialize provider in "MWS" mode to provision new workspace
provider "databricks" {
  alias    = "mws"
  host     = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  username = var.databricks_account_username
  password = var.databricks_account_password
}

data "terraform_remote_state" "unity" {
  backend = "local"

  config = {
    path = "account-level/terraform.tfstate.d/${var.databricks_account_name}/terraform.tfstate"
  }
}
