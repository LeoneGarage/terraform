variable "databricks_client_id" {
  type = string
}
variable "databricks_client_secret" {
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

variable "aws_profile" {
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

variable "metastore_id" {
  default = ""
}

locals {
  prefix = var.databricks_workspace_name
}
