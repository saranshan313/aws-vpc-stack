locals {
  regions = {
    "use1"  = "us-east-1"
    "apse2" = "ap-southeast-2"
  }
  settings = yamldecode(file("${var.TFC_WORKSPACE_NAME}.yaml"))
}

provider "aws" {
  region = local.regions[local.settings.region]

  default_tags {
    tags = {
      region = local.settings.region
      env    = local.settings.env
      owner  = "mohanraj.loganathan@slalom.com"
    }
  }
}

#data "aws_caller_identity" "current" {}
