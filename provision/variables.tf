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

variable "aws_profile" {
  default = ""
}
variable "required_az_total" {
  default = "2"
}

variable "tags" {
  default = {}
}

variable "cidr_block_host" {
  default = "10.0.0.0"
}

variable "cidr_block_prefix" {
  default = "16"
}

variable "subnet_offset" {
  default = 3
}

variable "region" {
  default = "ap-southeast-2"
}

variable "private_dns_enabled" {
  default = false
}

variable "databricks_workspace_name" {
  default = ""
}

variable "allow_outgoing_internet" {
  default = false
}

variable "cmk_managed" {
  default = true
}

variable "cmk_storage" {
  default = true
}

variable "front_end_pl_subnet_ids" {
  default = ""
}

variable "front_end_pl_source_subnet_ids" {
  default = ""
}

# Whether o make access to Workspace public or private.
# If private only access via specified Front End VPC Endpoint will be allowed.
# valid value are "", "private", "public"
variable "front_end_access" {
  default = ""
}

variable "private_link" {
  default = true
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

locals {
  prefix = var.databricks_workspace_name=="" ? "terratest-${random_string.naming.result}" : var.databricks_workspace_name
  cidr_block = "${var.cidr_block_host}/${var.cidr_block_prefix}"
  private_link = {
    "ap-southeast-2": {
      workspace_service = "com.amazonaws.vpce.ap-southeast-2.vpce-svc-0b87155ddd6954974"
      relay_service = "com.amazonaws.vpce.ap-southeast-2.vpce-svc-0b4a72e8f825495f6"
    }
    "us-east-1": {
      workspace_service = "com.amazonaws.vpce.us-east-1.vpce-svc-09143d1e626de2f04"
      relay_service = "com.amazonaws.vpce.us-east-1.vpce-svc-00018a8c3ff62ffdf"
    }
    "us-east-2": {
      workspace_service = "com.amazonaws.vpce.us-east-2.vpce-svc-041dc2b4d7796b8d3"
      relay_service = "com.amazonaws.vpce.us-east-2.vpce-svc-090a8fab0d73e39a6"
    }
    "us-west-2": {
      workspace_service = "com.amazonaws.vpce.us-west-2.vpce-svc-0129f463fcfbc46c5"
      relay_service = "com.amazonaws.vpce.us-west-2.vpce-svc-0158114c0c730c3bb"
    }
    "eu-west-1": {
      workspace_service = "com.amazonaws.vpce.eu-west-1.vpce-svc-0da6ebf1461278016"
      relay_service = "com.amazonaws.vpce.eu-west-1.vpce-svc-09b4eb2bc775f4e8c"
    }
    "eu-west-2": {
      workspace_service = "com.amazonaws.vpce.eu-west-2.vpce-svc-01148c7cdc1d1326c"
      relay_service = "com.amazonaws.vpce.eu-west-2.vpce-svc-05279412bf5353a45"
    }
    "eu-central-1": {
      workspace_service = "com.amazonaws.vpce.eu-central-1.vpce-svc-081f78503812597f7"
      relay_service = "com.amazonaws.vpce.eu-central-1.vpce-svc-08e5dfca9572c85c4"
    }
    "ap-southeast-1": {
      workspace_service = "com.amazonaws.vpce.ap-southeast-1.vpce-svc-02535b257fc253ff4"
      relay_service = "com.amazonaws.vpce.ap-southeast-1.vpce-svc-0557367c6fc1a0c5c"
    }
    "ap-northeast-1": {
      workspace_service = "com.amazonaws.vpce.ap-northeast-1.vpce-svc-02691fd610d24fd64"
      relay_service = "com.amazonaws.vpce.ap-northeast-1.vpce-svc-02aa633bda3edbec0"
    }
    "ap-south-1": {
      workspace_service = "com.amazonaws.vpce.ap-south-1.vpce-svc-0dbfe5d9ee18d6411"
      relay_service = "com.amazonaws.vpce.ap-south-1.vpce-svc-03fd4d9b61414f3de"
    }
    "ca-central-1": {
      workspace_service = "com.amazonaws.vpce.ca-central-1.vpce-svc-0205f197ec0e28d65"
      relay_service = "com.amazonaws.vpce.ca-central-1.vpce-svc-0c4e25bdbcbfbb684"
    }
  }

  small_subnet_cidrs = [for i in range(0, 10) : cidrsubnet(cidrsubnet(local.cidr_block, var.subnet_offset, pow(2, var.subnet_offset)-1),
   32 - var.cidr_block_prefix - var.subnet_offset - 4,
    pow(2, 32 - var.cidr_block_prefix - var.subnet_offset - 4) - 1 - i)]

  required_azs = var.required_az_total == "all" ? length(data.aws_availability_zones.available.names) : tonumber(var.required_az_total)
}