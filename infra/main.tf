resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  resource_group_name = azurerm_resource_group.this.name
  name                = local.name
  location            = var.location

  address_space = [
    "10.1.0.0/16",
  ]
  tags = local.tags
}

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.this.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.this.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.this.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.this.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.this.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.this.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.this.name}-rdrcfg"
}

resource "azurerm_subnet" "subnet_keyvault" {
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_resource_group.this.name
  name                 = "snet_endpoint"

  address_prefixes = [
    "10.1.1.0/24",
  ]
}

resource "azurerm_subnet" "database" {
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_resource_group.this.name
  name                 = "snet_database_name"

  address_prefixes = [
    "10.1.2.0/24",
  ]

  delegation {
    name = "Microsoft.DBforPostgreSQL/serversv2"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/serversv2"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}


resource "azurerm_subnet" "springapps" {
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_resource_group.this.name
  name                 = "snet_springapp"

  address_prefixes = [
    "10.1.3.0/24",
  ]
}

resource "azurerm_subnet" "waf" {
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_resource_group.this.name
  name                 = "snet_waf"

  address_prefixes = [
    "10.1.4.0/24",
  ]
}

resource "azurerm_application_gateway" "this" {
  resource_group_name = azurerm_resource_group.this.name
  name                = "appgateway"
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  backend_address_pool {
    name = local.name
    fqdns = [
      azurerm_spring_cloud_app.this.fqdn,
    ]
  }

  backend_http_settings {
    name                  = local.name
    request_timeout       = 60
    protocol              = "Http"
    port                  = 80
    cookie_based_affinity = "Disabled"
  }

  frontend_ip_configuration {
    public_ip_address_id = azurerm_public_ip.public_ip.id
    name                 = "fe-config"
  }

  frontend_port {
    port = 80
    name = "fe-port"
  }

  gateway_ip_configuration {
    subnet_id = azurerm_subnet.waf.id
    name      = "${local.name}-gateway-ip-configuration"
  }

  http_listener {
    protocol                       = "Http"
    name                           = "be-listener"
    frontend_port_name             = "fe-port"
    frontend_ip_configuration_name = "fe-config"
  }

  request_routing_rule {
    rule_type                  = "Basic"
    name                       = "demo-rqrt"
    http_listener_name         = "be-listener"
    backend_http_settings_name = "demo-bhs"
    backend_address_pool_name  = "springapp_ap"
  }

  sku {
    tier     = "Standard"
    name     = "Standard_Small"
    capacity = 2
  }

  waf_configuration {
    rule_set_version = "3.1"
    rule_set_type    = "OWASP"
    firewall_mode    = "Prevention"
    enabled          = false ##
    disabled_rule_group {
      rule_group_name = "REQUEST-941-APPLICATION-ATTACK-XSS"
    }
  }
}

resource "azurerm_spring_cloud_service" "this" {
  name                = "${local.name}-svc"
  location            = var.location
  zone_redundant      = true
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_spring_cloud_app" "this" {
  service_name        = azurerm_spring_cloud_service.this.name
  resource_group_name = azurerm_resource_group.this.name
  name                = "${local.name}-app"
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "private.foo"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_public_ip" "public_ip" {
  resource_group_name = azurerm_resource_group.this.name
  name                = "pip-ag"
  location            = azurerm_resource_group.this.location
  allocation_method   = "Dynamic"
  tags                = local.tags
}

resource "azurerm_dns_zone" "dns_zone" {
  resource_group_name = azurerm_resource_group.this.name
  name                = "publicdns.com"
  tags                = local.tags
}
