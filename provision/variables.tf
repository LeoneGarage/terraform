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

variable "aws_access_key" {
  default = ""
}

variable "aws_secret_key" {
  default = ""
}

variable "tags" {
  default = {}
}

variable "cidr_block" {
  default = "10.0.0.0/16"
}

variable "subnet_offset" {
  default = 3
}

variable "cidr_pl_block" {
  default = "10.0.0.0/28"
}


variable "region" {
  default = "ap-southeast-2"
}

variable "private_dns_enabled" {
  default = false
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

locals {
  prefix = "terratest"//"demo${random_string.naming.result}"
  private_link = {
    workspace_service = "com.amazonaws.vpce.ap-southeast-2.vpce-svc-0b87155ddd6954974"
    relay_service = "com.amazonaws.vpce.ap-southeast-2.vpce-svc-0b4a72e8f825495f6"
  }
}