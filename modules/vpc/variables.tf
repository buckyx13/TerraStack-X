variable "cidr" {
  description = "VPC CIDR block"
  type = string
}

variable "name" {
  description = "Name prefix"
  type = string
}

variable "azs" {
  description = "Availability zones to span"
  type = list(string)
}

variable "public_subnet_cidrs" {
  description = "One public subnet CIDR per AZ"
  type = list(string)
}

variable "private_subnet_cidrs" {
  description = "One private subnet CIDR per AZ"
  type = list(string)
}

variable "single_nat_gateway" {
  description = "true = one shared NAT (dev); false = one NAT per AZ (HA, prod)"
  type = bool
  default = false
}

variable "flow_log_retention_days" {
  description = "Flow log retention in days"
  type = number
  default = 30
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt the flow log group"
  type = string
}