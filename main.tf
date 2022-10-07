
data "aws_caller_identity" "current" {}

data "template_file" "kms_policy_document" {
  template = file("${path.module}/templates/kms_access_policy.tpl")
  vars = {
    account_id = "${data.aws_caller_identity.current.account_id}"
    user       = "cloud_user"
  }
}

resource "aws_kms_key" "encryption_key" {
  description              = "KMS key used for encrypting terraform state data"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage                = "ENCRYPT_DECRYPT"
  policy                   = data.template_file.kms_policy_document.rendered
}

resource "aws_dynamodb_table" "locK_table" {
  name           = var.tf_state_lock_table
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.encryption_key.arn
  }
}


resource "aws_s3_bucket" "tfstate_bucket" {
  bucket = var.tf_state_bucket
}
resource "aws_s3_bucket_server_side_encryption_configuration" "name" {
  bucket = aws_s3_bucket.tfstate_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.encryption_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "tfstate_bucket_versionning" {
  bucket = aws_s3_bucket.tfstate_bucket.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

data  template_file "terraform_config_template" {
  template = file("${path.module}/templates/terraform.tpl")
  vars = {
    profile = var.profile
    region       = var.region
    s3_bucket = var.tf_state_bucket
    dynamodb_table = var.tf_state_lock_table
    kms_key_id = aws_kms_key.encryption_key.id
    tf_state_key = var.tf_state_key
  }
}

resource "local_file" "terraform_config" {
    content  = data.template_file.terraform_config_template.rendered
    filename = "${path.module}/example/terraform.tf"
    file_permission = "0644"
}

output "kms_key_id" {
  value = aws_kms_key.encryption_key.id
}

output "bucket" {
  value = aws_s3_bucket.tfstate_bucket.bucket
}
output "table" {
  value = aws_dynamodb_table.locK_table.name
}
