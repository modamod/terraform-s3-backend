
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "${s3_bucket}"
    key    = "${tf_state_key}"
    profile = "${profile}"
    region = "${region}"
    encrypt = true
    kms_key_id = "${kms_key_id}"
    dynamodb_table = "${dynamodb_table}"
  }
}
