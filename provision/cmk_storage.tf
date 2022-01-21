data "aws_iam_policy_document" "databricks_storage_cmk" {
  version = "2012-10-17"
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid    = "Allow Databricks to use KMS key for DBFS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::414351767826:root"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "Allow Databricks to use KMS key for DBFS (Grants)"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::414351767826:root"]
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
  statement {
    sid    = "Allow Databricks to use KMS key for EBS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cross_account_role.arn]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "kms:ViaService"
      values   = ["ec2.*.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "storage_customer_managed_key" {
  count = var.cmk_storage ? 1 : 0
  policy = data.aws_iam_policy_document.databricks_storage_cmk.json
  tags = var.tags
}

resource "aws_kms_alias" "storage_customer_managed_key_alias" {
  count = var.cmk_storage ? 1 : 0
  name          = "alias/${local.prefix}-storage-customer-managed-key-alias"
  target_key_id = aws_kms_key.storage_customer_managed_key[0].key_id
}

resource "databricks_mws_customer_managed_keys" "storage" {
  count = var.cmk_storage ? 1 : 0
  provider        = databricks.mws
  account_id = var.databricks_account_id
  aws_key_info {
    key_arn   = aws_kms_key.storage_customer_managed_key[0].arn
    key_alias = aws_kms_alias.storage_customer_managed_key_alias[0].name
  }
  use_cases = ["STORAGE"]
}