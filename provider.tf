terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  alias   = "west2"
  region  = "eu-west-2"
  profile = "default"
}
provider "aws" {
  alias   = "west1"
  region  = "eu-west-1"
  profile = "default"
}