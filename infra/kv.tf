resource "random_string" "kv_random_string" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_key_vault" "key_vault_main" {
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  tags                        = local.tags
  soft_delete_retention_days  = 7
  sku_name                    = "standard"
  resource_group_name         = azurerm_resource_group.this.name
  purge_protection_enabled    = false
  name                        = "kv-${random_string.kv_random_string.result}"
  location                    = var.location
  enabled_for_disk_encryption = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "Get",
      "Create",
      "List",
    ]
    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover",
      "List",
    ]
    storage_permissions = [
      "Get",
      "List",
    ]
  }
}

resource "azurerm_private_endpoint" "private_endpoint_keyvault" {
  tags                = local.tags
  subnet_id           = azurerm_subnet.springapps.id
  resource_group_name = azurerm_resource_group.this.name
  name                = "pe_keyvault"
  location            = var.location

  private_service_connection {
    private_connection_resource_id = azurerm_key_vault.key_vault_main.id
    name                           = "connectiontokv"
    is_manual_connection           = false
    subresource_names = [
      "Vault",
    ]
  }
}

