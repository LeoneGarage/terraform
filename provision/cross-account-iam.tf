data "databricks_aws_assume_role_policy" "this" {
  external_id = var.databricks_account_id
}

resource "aws_iam_role" "cross_account_role" {
  name               = "${local.prefix}-crossaccount"
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
  tags               = var.tags
}

locals {
    policy_json = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "Stmt1403287045000",
                "Effect": "Allow",
                "Action": [
                    "ec2:AssociateIamInstanceProfile",
                    "ec2:AttachVolume",
                    "ec2:AuthorizeSecurityGroupEgress",
                    "ec2:AuthorizeSecurityGroupIngress",
                    "ec2:CancelSpotInstanceRequests",
                    "ec2:CreateTags",
                    "ec2:CreateVolume",
                    "ec2:DeleteTags",
                    "ec2:DeleteVolume",
                    "ec2:DescribeAvailabilityZones",
                    "ec2:DescribeIamInstanceProfileAssociations",
                    "ec2:DescribeInstanceStatus",
                    "ec2:DescribeInstances",
                    "ec2:DescribeInternetGateways",
                    "ec2:DescribeNatGateways",
                    "ec2:DescribeNetworkAcls",
                    "ec2:DescribePrefixLists",
                    "ec2:DescribeReservedInstancesOfferings",
                    "ec2:DescribeRouteTables",
                    "ec2:DescribeSecurityGroups",
                    "ec2:DescribeSpotInstanceRequests",
                    "ec2:DescribeSpotPriceHistory",
                    "ec2:DescribeSubnets",
                    "ec2:DescribeVolumes",
                    "ec2:DescribeVpcAttribute",
                    "ec2:DescribeVpcs",
                    "ec2:DetachVolume",
                    "ec2:DisassociateIamInstanceProfile",
                    "ec2:ReplaceIamInstanceProfileAssociation",
                    "ec2:RequestSpotInstances",
                    "ec2:RevokeSecurityGroupEgress",
                    "ec2:RevokeSecurityGroupIngress",
                    "ec2:RunInstances",
                    "ec2:TerminateInstances"
                ],
                "Resource": [
                    "*"
                ]
            },
            {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "${aws_iam_role.user_role.arn}"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "iam:CreateServiceLinkedRole",
                    "iam:PutRolePolicy"
                ],
                "Resource": "arn:aws:iam::*:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot",
                "Condition": {
                    "StringLike": {
                        "iam:AWSServiceName": "spot.amazonaws.com"
                    }
                }
            }
        ]
    }
}

data "databricks_aws_crossaccount_policy" "this" {
}

resource "aws_iam_role_policy" "this" {
  name   = "${local.prefix}-policy"
  role   = aws_iam_role.cross_account_role.id
  policy = jsonencode(local.policy_json)//data.databricks_aws_crossaccount_policy.this.json
}

resource "databricks_mws_credentials" "this" {
  provider         = databricks.mws
  role_arn         = aws_iam_role.cross_account_role.arn
  credentials_name = "${local.prefix}-creds"
  depends_on       = [
      time_sleep.wait,
      aws_iam_role_policy.this
      ]
}