output "kms_key_id" {
  value = aws_kms_key.encryption_key
  description = "KMS key used to encrypt the data in S3 and dynamodb tablee"
}

output "bucket" {
  value = aws_s3_bucket.tfstate_bucket.bucket
  description = "The s3 bucket used to store the terraform state"
}
output "table" {
  value = aws_dynamodb_table.locK_table
  description = "Dynamodb table used for locking when applying configration"
}

output "terraform_config" {
  value = data.template_file.terraform_config_template.rendered
  description = "Terraform backend configuration file content"
}
