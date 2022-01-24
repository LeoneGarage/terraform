locals {
    account_name = var.databricks_account_name
}

resource "aws_s3_bucket" "logdelivery" {
  bucket = "${local.account_name}-logdelivery"
  acl    = "private"
  versioning {
    enabled = false
  }
  force_destroy = true
  tags = merge(var.tags, {
    Name = "${local.account_name}-logdelivery"
  })
}

resource "aws_s3_bucket_public_access_block" "logdelivery" {
  bucket                  = aws_s3_bucket.logdelivery.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

data "databricks_aws_assume_role_policy" "logdelivery" {
  external_id      = var.databricks_account_id
  for_log_delivery = true
}

resource "aws_iam_role" "logdelivery" {
  name               = "${local.account_name}-logdelivery"
  description        = "(${local.account_name}) UsageDelivery role"
  assume_role_policy = data.databricks_aws_assume_role_policy.logdelivery.json
  tags               = var.tags
}

data "databricks_aws_bucket_policy" "logdelivery" {
  full_access_role = aws_iam_role.logdelivery.arn
  bucket           = aws_s3_bucket.logdelivery.bucket
}

resource "aws_s3_bucket_policy" "logdelivery" {
  bucket = aws_s3_bucket.logdelivery.id
  policy = data.databricks_aws_bucket_policy.logdelivery.json
}

resource "databricks_mws_credentials" "log_writer" {
  provider         = databricks.mws
  account_id       = var.databricks_account_id
  credentials_name = "Usage Delivery"
  role_arn         = aws_iam_role.logdelivery.arn

  depends_on = [
    aws_s3_bucket_policy.logdelivery
  ]
}

resource "databricks_mws_storage_configurations" "log_bucket" {
  provider                   = databricks.mws
  account_id                 = var.databricks_account_id
  storage_configuration_name = "Usage Logs"
  bucket_name                = aws_s3_bucket.logdelivery.bucket

  depends_on = [
    aws_s3_bucket_policy.logdelivery
  ]
}

resource "databricks_mws_log_delivery" "usage_logs" {
  provider                 = databricks.mws
  account_id               = var.databricks_account_id
  credentials_id           = databricks_mws_credentials.log_writer.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.log_bucket.storage_configuration_id
  delivery_path_prefix     = "billable-usage"
  config_name              = "Usage Logs"
  log_type                 = "BILLABLE_USAGE"
  output_format            = "CSV"
}

resource "databricks_mws_log_delivery" "audit_logs" {
  provider                 = databricks.mws
  account_id               = var.databricks_account_id
  credentials_id           = databricks_mws_credentials.log_writer.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.log_bucket.storage_configuration_id
  delivery_path_prefix     = "audit-logs"
  config_name              = "Audit Logs"
  log_type                 = "AUDIT_LOGS"
  output_format            = "JSON"
}