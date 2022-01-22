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