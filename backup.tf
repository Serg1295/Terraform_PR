terraform {
  backend "s3" {
    bucket = "sergo.tfstatebucket"
    key    = "P161/terraform.tfstate"
    region = "eu-central-1"
  }
}