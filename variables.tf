variable "tags" {
  type = map(string)
}
variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "key_name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}
variable "asg_name" {
  type = string
}

variable "tf_state_bucket" {
  type = string
}

variable "user" {
  type = string
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
}
variable "tf_state_key" {
  type = string
}
