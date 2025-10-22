terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.70.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}

# Kubernetes provider configured with data from infrastructure workspace
provider "kubernetes" {
  host                   = data.tfe_outputs.infrastructure.values.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.tfe_outputs.infrastructure.values.eks_cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.tfe_outputs.infrastructure.values.eks_cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

# Helm provider configured similarly
provider "helm" {
  kubernetes {
    host                   = data.tfe_outputs.infrastructure.values.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(data.tfe_outputs.infrastructure.values.eks_cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        data.tfe_outputs.infrastructure.values.eks_cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

# TFE provider (uses TFE_TOKEN environment variable or token from CLI config)
provider "tfe" {
  hostname = var.tfe_hostname
}