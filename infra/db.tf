resource "azurerm_postgresql_server" "this" {
  name                = "${local.name}-postgresql-server"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = "psqladmin"
  administrator_login_password = var.admin_password
  version                      = "9.5"
  ssl_enforcement_enabled      = true
  tags                         = local.tags
}

resource "azurerm_postgresql_database" "this" {
  name                = "${local.name}-db"
  resource_group_name = azurerm_resource_group.this.name
  server_name         = azurerm_postgresql_server.this.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}
