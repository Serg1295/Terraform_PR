data "aws_availability_zones" "available" {}
data "aws_vpc" "default" {
  default = true
}
data "aws_ami" "latest_ubuntu" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-*"]
  }
}
data "aws_key_pair" "Frankfurt_key" {}
locals {
  local_data = jsondecode(file("manifest.json"))
  artifact_id = [for art in local.local_data.builds : art.artifact_id]
}

output "show_locals" {
  value = split(":",local.artifact_id[0])[1]
}