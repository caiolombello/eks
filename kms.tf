resource "aws_kms_key" "kms_key" {
  description             = "KMS key for secret encryption"
  deletion_window_in_days = 10
  key_usage               = "ENCRYPT_DECRYPT"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY
}