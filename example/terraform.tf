
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "moda-test-bucket"
    key    = "terraform-us-esat-1.tfstate"
    profile = "default"
    region = "us-east-1"
    encrypt = true
    kms_key_id = "b748642b-f66f-4389-b38e-d425a032c86a"
    dynamodb_table = "lock_table-us-east-1"
  }
}
