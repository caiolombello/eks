terraform {
  required_version = ">= 1.3.1"

  # providers - 4.33.0 the last version on 04/10/2022
  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.33.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.19.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 2.1.0"
    }
  }
}