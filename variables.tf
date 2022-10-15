variable "tags" {
  type = map(string)

}
variable "tf_state_bucket" {
  type = string
  description = "Bucket name to store terraform state file"
}

variable "profile" {
  type = string
  description = "Profile to use to access remote backend bucket and dynamodb lock table"
}

variable "region" {
  type = string
  description = "Region to use to access remote backend bucket and dynamodb lock table"
}

variable "tf_state_lock_table" {
  type = string
  default = "Dynamodb table name to store the lock information."
}
variable "tf_state_key" {
  type = string
  description = "Terraform state key to store in the s3 bucket."
}

variable "version_retention_period" {
  type = number
  default = 15
  description = "Number of days to retain pervious state versions, defaults to 15 days"
}
