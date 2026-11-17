variable "region" {
  description = "AWs region for the state bucket"
  type = string
  default = "us-east-1"
}

variable "project" {
  description = "Short Project name used as a resource prefix"
  type = string
  default = "project-z"
}

variable "tags" {
  description = "Tags applied to bootstrap resources"
  type = map(string)
  default = {
    Project = "project-z"
    Environment = "shared"
    ManagedBy = "terraform"
  }
}