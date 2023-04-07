terraform {
  required_version = ">= 1.3.1"


  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.19.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 2.1.0"
    }
  }
}