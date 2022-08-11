variable "environment" {
  type        = string
  description = "Product environment"
}

variable "product_name" {
  type        = string
  description = "Application Name"
  default     = "terraform_starter"
}

variable "root_domain_name" {
  type        = string
  description = "Domain name for root"
}
