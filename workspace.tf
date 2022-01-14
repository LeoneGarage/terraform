resource "time_sleep" "wait" {
  depends_on = [
  aws_iam_role.cross_account_role]
  create_duration = "20s"
}

resource "databricks_mws_workspaces" "this" {
  provider        = databricks.mws
  account_id      = var.databricks_account_id
  aws_region      = var.region
  workspace_name  = local.prefix
  deployment_name = local.prefix

  credentials_id           = databricks_mws_credentials.this.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id               = databricks_mws_networks.this.network_id
  private_access_settings_id = databricks_mws_private_access_settings.pas.private_access_settings_id

  pricing_tier               = "ENTERPRISE"

  token {
    comment = "Terraform"
  }

  depends_on = [
      time_sleep.wait,
      databricks_mws_networks.this
  ]
}

output "databricks_host" {
  value = databricks_mws_workspaces.this.workspace_url
}

output "databricks_token" {
  value     = databricks_mws_workspaces.this.token[0].token_value
  sensitive = true
}