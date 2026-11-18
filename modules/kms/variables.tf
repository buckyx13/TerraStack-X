variable "name" {
  description = "Name prefix"
  type = string
}

variable "deletion_window_in_days" {
  description = "KMS key deletion waiting period"
  type = number
  default = 30
}