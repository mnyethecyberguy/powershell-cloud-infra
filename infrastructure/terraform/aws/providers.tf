terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.68.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.5"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "2.6.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }

  backend "s3" {
    profile = "default"
    key     = "tfstate"
  }
}

provider "aws" {
  profile = "default"
}
