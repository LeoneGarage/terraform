locals {
  role_arn         = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.databricks_account_name}-metastore-access"
}

data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "metastore" {
  bucket = "${var.databricks_account_name}-metastore"
  // destroy all objects with bucket destroy
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "metastore_bucket_versioning" {
  bucket = aws_s3_bucket.metastore.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "external" {
  bucket             = aws_s3_bucket.metastore.id
  ignore_public_acls = true
  depends_on         = [aws_s3_bucket.metastore]
}

data "aws_iam_policy_document" "passrole_for_uc" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"]
      type        = "AWS"
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.databricks_account_id]
    }
  }
  statement {
    sid     = "ExplicitSelfRoleAssumption"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      type        = "AWS"
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = [local.role_arn]
    }
  }
}

resource "aws_iam_policy" "metastore_data_access" {
  // Terraform's "jsonencode" function converts a
  // Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${var.databricks_account_name}-metastore-access"
    Statement = [
      {
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          aws_s3_bucket.metastore.arn,
          "${aws_s3_bucket.metastore.arn}/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "sts:AssumeRole"
        ],
        "Resource" : [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.databricks_account_name}-metastore-access"
        ],
        "Effect" : "Allow"
      },
    ]
  })
  tags = merge(var.tags, {
    Name = "${local.prefix}-unity-catalog metastore IAM policy"
  })
}

resource "aws_iam_role" "metastore_data_access" {
  name                = "${var.databricks_account_name}-metastore-access"
  assume_role_policy  = data.aws_iam_policy_document.passrole_for_uc.json
  managed_policy_arns = [aws_iam_policy.metastore_data_access.arn]
  tags = merge(var.tags, {
    Name = "${local.prefix}-unity-catalog metastore access IAM role"
  })
}

resource "databricks_metastore" "this" {
  provider      = databricks.mws
  name          = "${var.region}-${var.databricks_account_name}-metastore"
  storage_root  = "s3://${aws_s3_bucket.metastore.bucket}"
  region        = var.region
  force_destroy = true
}

resource "databricks_metastore_data_access" "this" {
  provider      = databricks.mws
  metastore_id  = databricks_metastore.this.id
  name          = aws_iam_role.metastore_data_access.name
  aws_iam_role {
    role_arn    = aws_iam_role.metastore_data_access.arn
  }
  is_default    = true
  force_destroy = true
}
