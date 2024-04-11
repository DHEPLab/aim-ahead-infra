variable "env" {
  description = "enviroment"
  type        = string
  validation {
    condition     = can(regex("^dev|prod$", var.env))
    error_message = "Deploy envirment must follow regex(\"^dev|prod$\") rule."
  }
}

variable "project_name" {
  description = "project name"
  type        = string
}

variable "api_image_uri" {
  description = "api image uri"
  type        = string
}

variable "app_image_uri" {
  description = "app image uri"
  type        = string
}

variable "region" {
  type = string
}

variable "database_url" {
  type = string
}
