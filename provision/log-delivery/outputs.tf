output "databricks_metastore_id" {
  value = var.metastore_id==""?databricks_metastore.this[0].id:var.metastore_id
}
