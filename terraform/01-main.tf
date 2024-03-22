locals {
  regions = {
    "use1" = "us-east-1"
  }
  settings = yamldecode(file("${var.TFC_WORKSPACE_NAME}.yaml"))

  tags = {
    region = local.settings.region
    env    = local.settings.env
  }

}

provider "aws" {
  region = local.regions[local.settings.region]
}

#data "aws_caller_identity" "current" {}
