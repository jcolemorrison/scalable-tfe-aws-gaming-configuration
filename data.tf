# Read outputs from infrastructure workspace
data "tfe_outputs" "infrastructure" {
  organization = var.tfe_organization
  workspace    = var.infrastructure_workspace_name
}

# Extract OIDC provider ID from URL for IRSA trust policy
locals {
  oidc_provider_url = data.tfe_outputs.infrastructure.values.eks_oidc_provider_url
  oidc_provider_id  = replace(local.oidc_provider_url, "https://", "")
}
