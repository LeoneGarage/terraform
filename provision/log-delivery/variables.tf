variable "databricks_account_username" {
  type = string
}
variable "databricks_account_password" {
  type = string
  sensitive = true
}
variable "databricks_account_id" {
  type = string
  sensitive = true
}

variable "databricks_account_name" {
  type = string
}

variable "aws_access_key" {
  default = ""
}

variable "aws_secret_key" {
  default = ""
}

variable "tags" {
  default = {}
}

variable "region" {
  default = "ap-southeast-2"
}

variable "databricks_workspace_name" {
  default = ""
}

locals {
  prefix = var.databricks_workspace_name
}
