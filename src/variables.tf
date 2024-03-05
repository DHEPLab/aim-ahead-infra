variable "env" {
  description = "enviroment"
  type        = string
  validation {
    condition     = can(regex("^dev|prod$", var.env))
    error_message = "Env must follow regex(\"^dev|prod$\") rule."
  }
}


variable "region" {
  description = "cloud service region"
  type        = string
  default     = "us-east-1"
}

variable "proj_name" {
  description = "project name"
  type        = string
  default     = "aim-ahead"
}