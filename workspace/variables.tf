variable "aws_access_key" {
  default = ""
}

variable "aws_secret_key" {
  default = ""
}

variable "region" {
  default = ""
}

locals {
  region = length(var.region) > 0 ? var.region : data.terraform_remote_state.db.outputs.databricks_workspace_region
}