# AWS Load Balancer Controller outputs
output "lb_controller_iam_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.lb_controller.arn
}

output "lb_controller_iam_policy_arn" {
  description = "ARN of the IAM policy for AWS Load Balancer Controller"
  value       = aws_iam_policy.lb_controller.arn
}

output "lb_controller_service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = kubernetes_service_account.lb_controller.metadata[0].name
}

output "lb_controller_helm_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart"
  value       = helm_release.lb_controller.metadata[0].version
}

output "lb_controller_helm_status" {
  description = "Status of the Helm release"
  value       = helm_release.lb_controller.status
}

# Infrastructure references for convenience
output "eks_cluster_name" {
  description = "EKS cluster name from infrastructure workspace"
  value       = data.tfe_outputs.infrastructure.values.eks_cluster_name
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID from infrastructure workspace"
  value       = data.tfe_outputs.infrastructure.values.vpc_id
  sensitive   = true
}
