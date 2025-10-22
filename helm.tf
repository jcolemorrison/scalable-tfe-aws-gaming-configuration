# AWS Load Balancer Controller Helm chart
resource "helm_release" "lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.10.1" # Latest stable version compatible with EKS 1.31

  values = [
    yamlencode({
      clusterName = data.tfe_outputs.infrastructure.values.eks_cluster_name
      region      = var.aws_region
      vpcId       = data.tfe_outputs.infrastructure.values.vpc_id

      serviceAccount = {
        create = false
        name   = kubernetes_service_account.lb_controller.metadata[0].name
      }

      # High availability configuration
      replicaCount = 2

      podDisruptionBudget = {
        maxUnavailable = 1
      }

      # Enable WAFv2 support for advanced security features
      enableWafv2 = true

      # Use IP mode for target type (EKS standard with VPC CNI)
      defaultTargetType = "ip"

      # Logging level
      logLevel = "info"

      # Additional labels for resource tracking
      additionalLabels = {
        environment = "gaming-core"
        managed-by  = "terraform"
      }
    })
  ]

  depends_on = [
    kubernetes_service_account.lb_controller
  ]
}
