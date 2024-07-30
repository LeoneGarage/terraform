terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.49.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.15.0"
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
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}
