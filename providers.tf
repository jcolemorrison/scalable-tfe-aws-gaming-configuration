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

# Get authentication token for EKS cluster
data "aws_eks_cluster_auth" "cluster" {
  name = data.tfe_outputs.infrastructure.values.eks_cluster_name
}

# Kubernetes provider configured with data from infrastructure workspace
provider "kubernetes" {
  host                   = data.tfe_outputs.infrastructure.values.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.tfe_outputs.infrastructure.values.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Helm provider configured similarly
provider "helm" {
  kubernetes {
    host                   = data.tfe_outputs.infrastructure.values.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(data.tfe_outputs.infrastructure.values.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# TFE provider (uses TFE_TOKEN environment variable or token from CLI config)
provider "tfe" {
  hostname = var.tfe_hostname
}