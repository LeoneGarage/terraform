output "databricks_host" {
  value = databricks_mws_workspaces.this.workspace_url
}

output "databricks_token" {
  value     = databricks_mws_workspaces.this.token[0].token_value
  sensitive = true
}

output "databricks_workspace_name" {
  value = databricks_mws_workspaces.this.workspace_name
}

output "databricks_workspace_region" {
  value = var.region
}

output "databricks_account_name" {
  value = var.databricks_account_name
}

output "databricks_private_link" {
  value = var.private_link
}

output "databricks_allow_outgoing_internet" {
  value = var.allow_outgoing_internet
}
