# Terraform is declarative, so if we declare how our Infrastructure should look like in the end.
# If apply multiple times, the end result will be the same i.e., applying this twice WONT result in 2 EC2 instances
# Terraform keeps track of Infrastructure state in the 'terraform.tfstate' file and
# will use the file to diff desired infrastructure state vs actual infrastructure state


# aws provider lets us interact with the aws APIs with Terraform
# We can define variables for more flexibility
# In this case we have defined variables that Terraform recognises as Environment variables
variable "AWS_ACCESS_KEY_ID" {}     # Will be read from environment variable
variable "AWS_SECRET_ACCESS_KEY" {} # Will be read from environment variable
variable "AWS_DEFAULT_REGION" {}    # Will be read from environment variable
provider "aws" {
  #   version = "~> 2.0" Version is optional
  region     = var.AWS_DEFAULT_REGION
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

# resource "type_of_resource" "name_of_resource"
resource "aws_instance" "tf-ec2-test" {
  ami           = "ami-0c1bc246476a5572b" # Hard coded for now, but can use variables for more flexibility
  instance_type = "t2.micro"              # Free tier general purpose instance

  tags = {
    Name = "tf-ec2-test"
  }
}

