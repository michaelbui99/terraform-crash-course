terraform {
  backend "s3" {
    bucket         = "michaelbui99-terraform-test-state"
    key            = "global/s3/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-1"
}

# terraform.tfstate form will be stored in a s3 bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = "michaelbui99-terraform-test-state"

  lifecycle {
    prevent_destroy = true # Ensure that we do not delete our bucket through terraform destroy
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# dynamodb will be used for locking to ensure concurrent terraform changes will not result in corrupt state file and data loss
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
