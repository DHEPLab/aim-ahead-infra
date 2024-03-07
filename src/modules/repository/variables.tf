# variable "env" {
#   description = "enviroment"
#   type        = string
#   validation {
#     condition     = can(regex("^dev|prod$", var.env))
#     error_message = "Deploy envirment must follow regex(\"^dev|prod$\") rule."
#   }
# }

variable "project_name" {
  description = "project name"
  type        = string
}