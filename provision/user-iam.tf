resource "aws_iam_role" "user_role" {
  name               = "${local.prefix}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags               = merge(var.tags, {
                         Owner = var.databricks_object_owner
                       })
}

locals {
    role_policy_json = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "GrantCatalogAccessToGlue",
                "Effect": "Allow",
                "Action": [
                    "glue:*"
                ],
                "Resource": [
                    "*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:ListBucket"
                ],
                "Resource": [
                    "arn:aws:s3:::${local.prefix}-*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:DeleteObject",
                    "s3:PutObjectAcl"
                ],
                "Resource": [
                    "arn:aws:s3:::${local.prefix}-*/*"
                ]
            }
        ]
    }
}

resource "aws_iam_role_policy" "user_role_policy" {
  name   = "${local.prefix}-role-policy"
  role   = aws_iam_role.user_role.id
  policy = jsonencode(local.role_policy_json)
}

resource "aws_iam_instance_profile" "user_role_instance_profile" {
	name = aws_iam_role.user_role.name
	role = aws_iam_role.user_role.id
}