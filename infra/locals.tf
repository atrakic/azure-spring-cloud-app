locals {
  name = "spring-boot"
  tags = merge(var.tags, {
    env = "Development"
  })
}
