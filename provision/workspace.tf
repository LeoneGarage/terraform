resource "time_sleep" "wait" {
  depends_on = [
  aws_iam_role.cross_account_role,
  aws_iam_role_policy.this]
  create_duration = "20s"
}

resource "databricks_mws_workspaces" "this" {
  provider        = databricks.mws
  account_id      = var.databricks_account_id
  aws_region      = var.region
  workspace_name  = local.prefix
  deployment_name = var.no_deployment_prefix ? null : local.prefix

  credentials_id           = databricks_mws_credentials.this.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id               = databricks_mws_networks.this.network_id
  private_access_settings_id = var.private_link ? databricks_mws_private_access_settings.pas[0].private_access_settings_id : null

  managed_services_customer_managed_key_id = var.cmk_managed ? databricks_mws_customer_managed_keys.managed_services[0].customer_managed_key_id : null
  storage_customer_managed_key_id = var.cmk_storage ? databricks_mws_customer_managed_keys.storage[0].customer_managed_key_id : null

  token {
    comment = "Terraform"
  }

  depends_on = [
      time_sleep.wait,
      databricks_mws_networks.this
  ]
}

data "databricks_metastore" "this" {
  provider     = databricks.mws
  metastore_id = data.terraform_remote_state.unity.outputs.databricks_metastore_id
}

resource "databricks_metastore_assignment" "default_metastore" {
  provider             = databricks.mws
  workspace_id         = databricks_mws_workspaces.this.workspace_id
  metastore_id         = data.databricks_metastore.this.metastore_id
  default_catalog_name = "hive_metastore"
}