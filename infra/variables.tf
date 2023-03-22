variable "location" {
  type    = string
  default = "West Europe"
}

variable "tags" {
  description = "Default tags to apply to all resources."
  type        = map(any)
  default = {
  }
}

variable "admin_password" {
  type      = string
  default   = "Br@inb0ard"
  sensitive = true
}

