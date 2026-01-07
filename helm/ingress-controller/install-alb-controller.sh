#!/bin/bash
set -euo pipefail

# Set cluster name and namespace using Terragrunt outputs
CLUSTER_NAME=$(terragrunt output -raw eks_cluster_name --terragrunt-working-dir ../../live/dev/eks)
NAMESPACE=kube-system

# Get region, VPC ID, subnet IDs, ALB role ARN, and ECR URL from Terragrunt outputs
REGION=$(terragrunt output -raw region --terragrunt-working-dir ../../live/dev/vpc)
VPC_ID=$(terragrunt output -raw vpc_id --terragrunt-working-dir ../../live/dev/vpc)
SUBNET_IDS=$(terragrunt output -json private_subnet_ids --terragrunt-working-dir ../../live/dev/vpc | jq -r '.[]' | paste -sd "," -)
ALB_ROLE_ARN=$(terragrunt output -raw alb_controller_role_arn --terragrunt-working-dir ../../live/dev/alb)
ECR_URL=$(terragrunt output -raw ecr_repository_url --terragrunt-working-dir ../../live/dev/ecr)

# Create IAM role binding for the AWS Load Balancer Controller
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: ${NAMESPACE}
  annotations:
    eks.amazonaws.com/role-arn: ${ALB_ROLE_ARN}
EOF

# Install or upgrade the AWS Load Balancer Controller via Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n ${NAMESPACE} \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=${REGION} \
  --set vpcId=${VPC_ID} \
  --set subnetIds=${SUBNET_IDS}

# Optional: ECR login for test application deployment
kubectl run tmp-shell --image=amazon/aws-cli --rm -it --restart=Never -- sh -c "
  aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_URL}
"
