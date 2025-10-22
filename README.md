# AWS Gaming Infrastructure - Configuration

This Terraform workspace deploys Kubernetes configuration and controllers for the gaming-core EKS cluster.

## Purpose

Deploys the AWS Load Balancer Controller to enable:
- **Internet-facing Application Load Balancers (ALB)** for HTTP/HTTPS workloads
- **Network Load Balancers (NLB)** for TCP/UDP game servers
- **IngressGroup support** for sharing a single ALB across multiple applications

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ TFE Remote State (gaming-core-01-infrastructure)            │
│ ├── VPC Configuration                                       │
│ ├── EKS Cluster Details                                     │
│ └── OIDC Provider for IRSA                                  │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ IAM Resources (iam.tf)                                      │
│ ├── IAM Policy (AWS LB Controller permissions)             │
│ ├── IAM Role (IRSA trust policy)                           │
│ └── Policy Attachment                                       │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Kubernetes Resources (kubernetes.tf)                        │
│ └── Service Account (annotated with IAM role ARN)          │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Helm Release (helm.tf)                                      │
│ └── AWS Load Balancer Controller (v1.10.1)                 │
│     ├── Replicas: 2 (HA configuration)                     │
│     ├── Target Type: ip (EKS standard)                     │
│     └── WAFv2 Support: Enabled                             │
└─────────────────────────────────────────────────────────────┘
```

## Files

- **`providers.tf`** - Provider configurations (AWS, Kubernetes, Helm, TFE)
- **`variables.tf`** - Input variables
- **`data.tf`** - Remote state data source and locals
- **`iam.tf`** - IAM policy and role for AWS Load Balancer Controller
- **`kubernetes.tf`** - Kubernetes service account with IRSA annotation
- **`helm.tf`** - Helm release for AWS Load Balancer Controller
- **`outputs.tf`** - Output values

## Prerequisites

1. **Infrastructure Workspace Deployed**: The `gaming-core-01-infrastructure` workspace must be successfully deployed
2. **TFE Token**: Set `TFE_TOKEN` environment variable or configure in `~/.terraform.d/credentials.tfrc.json`
3. **AWS Credentials**: Configure AWS credentials that can assume the TFE role

## Deployment

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review Plan

```bash
terraform plan
```

### 3. Apply Configuration

```bash
terraform apply
```

## Verification

After deployment, verify the AWS Load Balancer Controller is running:

```bash
# Get cluster credentials (if not already configured)
aws eks update-kubeconfig \
  --region us-west-2 \
  --name gaming-core-cluster \
  --profile jcmibmgamingrole \
  --role-arn arn:aws:iam::632185211419:role/scalable-tfe-gaming-role

# Check controller pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Expected output (2 replicas):
# NAME                                           READY   STATUS    RESTARTS   AGE
# aws-load-balancer-controller-xxxxxxxxx-xxxxx   1/1     Running   0          2m
# aws-load-balancer-controller-xxxxxxxxx-xxxxx   1/1     Running   0          2m

# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify webhook is registered
kubectl get validatingwebhookconfigurations | grep aws-load-balancer
```

## Usage Patterns

### Pattern 1: Shared ALB with IngressGroup (Recommended for HTTP/HTTPS)

Multiple applications share a single Application Load Balancer using different routing rules:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: game-server-1
  annotations:
    alb.ingress.kubernetes.io/group.name: gaming-core-shared
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
  - host: game1.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: game-server-1
            port:
              number: 80
```

**Benefits:**
- Cost-effective (one ALB for multiple apps)
- Host-based or path-based routing
- Perfect for HTTP/HTTPS workloads
- Ideal for no-code module deployments

### Pattern 2: Dedicated NLB per Service (For TCP/UDP)

Each game server gets its own Network Load Balancer:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: game-server-udp
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
spec:
  type: LoadBalancer
  ports:
  - port: 7777
    protocol: UDP
    targetPort: 7777
  selector:
    app: game-server
```

## Outputs

After deployment, the following outputs are available:

- **`lb_controller_iam_role_arn`** - IAM role ARN (for reference in other workspaces)
- **`lb_controller_service_account_name`** - Kubernetes service account name
- **`lb_controller_helm_version`** - Installed chart version
- **`lb_controller_helm_status`** - Helm release status
- **`eks_cluster_name`** - Cluster name (from infrastructure workspace)
- **`vpc_id`** - VPC ID (from infrastructure workspace)

## Troubleshooting

### Controller pods not starting

```bash
# Check pod events
kubectl describe pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check IAM role assumption
kubectl get serviceaccount -n kube-system aws-load-balancer-controller -o yaml
# Verify the eks.amazonaws.com/role-arn annotation is present
```

### LoadBalancer not provisioning

```bash
# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller --tail=50

# Common issues:
# - Missing subnet tags (auto-discovery)
# - Security group issues
# - IAM permission errors
```

### Ingress not creating ALB

```bash
# Describe the ingress
kubectl describe ingress <ingress-name>

# Check events for errors
kubectl get events --sort-by='.lastTimestamp'
```

## Configuration Details

### Target Type: IP Mode

This deployment uses `defaultTargetType: ip` which:
- Registers pod IPs directly as ALB/NLB targets
- Eliminates NodePort overhead
- Works seamlessly with AWS VPC CNI
- Standard for modern EKS deployments
- Required for Fargate compatibility

### High Availability

The controller is deployed with:
- **2 replicas** for redundancy
- **Pod Disruption Budget** (maxUnavailable: 1)
- **Leader election** (only one actively reconciles)
- **system-cluster-critical** priority class

### WAFv2 Support

WAFv2 is enabled, allowing you to protect ALBs with AWS WAF:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: protected-ingress
  annotations:
    alb.ingress.kubernetes.io/wafv2-acl-arn: arn:aws:wafv2:...
```

## Next Steps

After deploying this configuration workspace:

1. **Test with a sample application** to verify load balancer provisioning
2. **Configure no-code modules** in TFE to deploy applications
3. **Set up DNS** for ingress hostnames
4. **Enable monitoring** for controller metrics

## Resources

- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Ingress Annotations Reference](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/annotations/)
- [Service Annotations Reference](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/service/annotations/)
