data "aws_iam_instance_profile" "initial" {
  name = "${local.prefix}-role"
}

resource "databricks_instance_profile" "initial" {
  instance_profile_arn = data.aws_iam_instance_profile.initial.arn
}
