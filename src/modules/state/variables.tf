variable "bucket_name" {
  description = "Remote S3 bucket mame"
  type        = string
  validation {
    condition     = can(regex("^([a-z0-9]{1}[a-z0-9-]{1,61}[a-z0-9]{1})$", var.bucket_name))
    error_message = "Bucket Name must not be empty and must follow S3 naming rules."
  }
}

variable "dynamodb_table" {
  description = "DynamoDB locking table name"
  type        = string
}