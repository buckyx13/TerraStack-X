variable "certificate_arn" {
  description = "ACM certificate ARN, null = HTTP only (dev); set = HTTPS with HTTP redirect"
  type = string
  default = null
}

variable "allowed_ingress_cidrs" {
  description = "CIDRs allowed to reach the ALB"
  type = list(string)
  default = [ "0.0.0.0/0" ]
}

variable "name" {
  description = "Name prefix (max 32 chars for the ALB name)"
  type = string
}

variable "vpc_id" {
  description = "VPC ID"
  type = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB"
  type = list(string)
}

variable "deletion_protection" {
  description = "Enable ALB deletion protection"
  type = bool
  default = false
}

variable "target_port" {
  description = "Port the app listens on"
  type = number
  default = 80
}

variable "health_check_path" {
  description = "Target group health check path"
  type = string
  default = "/"
}