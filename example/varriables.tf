variable "tf_state_profile" {
  type = string
  default = "default"
}

variable "profile" {
  default = "default"
}

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

variable "domain" {
  type = string
}

variable "pub_key_path" {
  type = string
}
