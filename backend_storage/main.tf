resource "azurerm_resource_group" "state_rg" {
  location = "eastus"
  name     = "bambrane-runner-state"
}

resource "azurerm_user_assigned_identity" "state_storage_account" {
  location            = azurerm_resource_group.state_rg.location
  name                = "state-storage-account"
  resource_group_name = azurerm_resource_group.state_rg.name
}

resource "azurerm_storage_account" "state" {
  account_replication_type      = "ZRS"
  account_tier                  = "Standard"
  account_kind                  = "StorageV2"
  location                      = azurerm_resource_group.state_rg.location
  name                          = "tfmod1espoolstatestorage"
  resource_group_name           = azurerm_resource_group.state_rg.name
  public_network_access_enabled = true

  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.storage_encryption_key.id
    user_assigned_identity_id = azurerm_user_assigned_identity.state_storage_account.id
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.state_storage_account.id]
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "state" {
  name                 = "azure-verified-tfmod-runner-state"
  storage_account_name = azurerm_storage_account.state.name

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "plan" {
  name                 = "azure-verified-tfmod-pull-request-plans"
  storage_account_name = azurerm_storage_account.state.name

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "telemetry" {
  name                 = "azure-verified-module-telemetry"
  storage_account_name = azurerm_storage_account.state.name

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_user_assigned_identity" "bambrane_operator" {
  location            = azurerm_resource_group.state_rg.location
  name                = "bambrane_operator"
  resource_group_name = azurerm_resource_group.state_rg.name
}

resource "azurerm_role_assignment" "storage_contributor" {
  principal_id = azurerm_user_assigned_identity.bambrane_operator.principal_id
  scope        = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
}

data azurerm_client_config this {}

resource "azurerm_role_assignment" "subscription_contributor" {
  principal_id = azurerm_user_assigned_identity.bambrane_operator.principal_id
  scope        = "/subscriptions/${data.azurerm_client_config.this.subscription_id}"
  role_definition_name = "Contributor"
}
