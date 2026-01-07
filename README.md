# Private EKS PoC: OpenVPN, Internal ALB, Private Route53, Persistent ECR/S3

This repository provides a production-style, minimal-cost AWS EKS cluster using **private subnets only**, accessible via OpenVPN, with an internal ALB, private Route53 DNS, and persistent ECR/S3 resources. All infrastructure is managed with **Terraform modules** and **Terragrunt** for environment orchestration.

---

## 🏗️ Directory Structure

```
.
├── README.md
├── modules/                # All reusable Terraform modules
│   ├── alb/                # Internal ALB (official module)
│   ├── eks/                # EKS cluster (official module)
│   ├── openvpn/            # OpenVPN EC2 instance
│   ├── route53/            # Private Route53 zone/records (official module)
│   ├── s3/                 # S3 bucket (official module, reusable)
│   ├── security/           # Security groups (official module)
│   └── vpc/                # VPC & subnets (official module)
├── live/
│   └── dev/                # Dev environment (Terragrunt stack)
│       ├── vpc/            # VPC stack
│       ├── eks/            # EKS stack
│       ├── openvpn/        # OpenVPN stack
│       ├── alb/            # ALB stack
│       ├── route53/        # Route53 stack
│       ├── security/       # Security stack
│       ├── persistent/     # Persistent ECR stack
│       ├── s3-app-data/    # S3 bucket for app data
│       └── s3-logs/        # S3 bucket for logs
└── scripts/
    ├── Makefile            # `make -f scripts/Makefile <target>`
    ├── install-alb-controller.sh
    └── deploy-test-app.sh
```

---

## 📋 Prerequisites

- AWS CLI + `aws configure` (us-east-1)
- Terraform >= 1.14.3
- Terragrunt >= 0.96.1
- kubectl
- Helm 3+
- EC2 Key Pair: Create one named `mint-eks-key` in us-east-1
- OpenVPN client (for VPN access)

### Install Terraform and Terragrunt (macOS/Homebrew)

```sh
brew install terraform
brew install terragrunt
```

---

## 🚀 Deployment Workflow

```
# 1. Deploy all infrastructure (from repo root)
cd live/dev
terragrunt run --all apply

# 2. Get OpenVPN public IP
terragrunt output --terragrunt-working-dir openvpn | grep openvpn_public_ip
```

**Key Outputs:**
- `eks_cluster_name` = mint-poc-eks-cluster
- `openvpn_public_ip` = <EC2 IP> (SSH here to finish VPN setup)
- `vpc_id` = vpc-xxxxxx
- `private_zone_name` = poc.internal.

---

## 🔐 Access via OpenVPN

1. **SSH to OpenVPN instance:**
   ```
   ssh -i mint-eks-key.pem ec2-user@<openvpn_public_ip>
   ```
2. **Complete OpenVPN setup** (see openvpn module README or script)
3. **Connect VPN client** → now `poc.internal` resolves privately

---

## 🧪 Test the Private App

From a **VPN-connected machine**:

```
# Update kubeconfig
terragrunt output --terragrunt-working-dir eks > kubeconfig.yaml
export KUBECONFIG=$(pwd)/kubeconfig.yaml

# Deploy test app + internal ALB
bash ../scripts/deploy-test-app.sh

# Test private access
nslookup hello.poc.internal    # → Resolves via private Route53
curl hello.poc.internal        # → 200 OK from private ALB → EKS pods
```

---

## 🔄 Makefile & Terragrunt Targets

```
make -f scripts/Makefile init         # terraform/terragrunt init
make -f scripts/Makefile plan         # terraform/terragrunt plan
make -f scripts/Makefile apply        # Deploy infra
make -f scripts/Makefile destroy      # Teardown (persistent resources survive)
make -f scripts/Makefile kubeconfig   # Update kubeconfig
make -f scripts/Makefile full-poc     # Full workflow
```

Or use Terragrunt directly in `live/dev`:
- `terragrunt run --all plan`
- `terragrunt run --all apply`
- `terragrunt run --all destroy`

---

## 🏗️ Architecture Diagram

```
Internet → OpenVPN (t3.micro, public subnet)
         ↓ (VPN tunnel)
Private Route53 (poc.internal) → Internal ALB (private subnets)
                                 ↓
                            EKS Cluster (t3.small nodes, private)
Persistent ECR/S3 (private endpoints)
```

- **VPC**: 10.0.0.0/20 (2 public / 2 private subnets)
- **EKS**: Private API endpoint, t3.small ON_DEMAND nodes (2 desired)
- **ALB**: Internal scheme, security group = VPC-only
- **DNS**: Private hosted zone, VPN required for resolution
- **ECR/S3**: Persistent, private endpoints only

---

## 💰 Cost (PoC, us-east-1)

| Resource         | Type         | Monthly Est. |
|------------------|--------------|--------------|
| EKS Control Plane| 1 cluster    | $73          |
| EKS Nodes        | 2x t3.small  | $18          |
| OpenVPN          | t3.micro     | $4           |
| NAT Gateway      | 1 (single-AZ)| $5 + data    |
| ALB              | Internal     | $18 + LCU    |
| ECR/S3           | Persistent   | $1-5         |
| **Total**        |              | **~$120/mo** |

**Destroy immediately after PoC!**

---

## 🔧 Customization

- **Domain**: Change `poc.internal` in `route53` module
- **More apps**: Add Ingress `host: myapp.poc.internal` → auto-provisions ALB rules
- **Production**:
  - Multi-AZ NAT gateways
  - EKS managed node groups → Fargate
  - AWS Gateway API controller
  - Full private EKS endpoint (VPC endpoints)

---

## 🧹 Cleanup

```
terragrunt run --all destroy
```

---

## ❓ Troubleshooting

- **kubectl no auth**: `make -f scripts/Makefile kubeconfig` (run via VPN)
- **ALB controller 403**: Check IRSA role ARN in `alb` module
- **DNS not resolving**: Must be VPN-connected + VPC DNS enabled
- **OpenVPN broken**: SSH to instance, check `systemctl status openvpn-server`

---

## Creating the EKS Key Pair
Before deploying the EKS cluster, you must create the EC2 key pair for SSH access to worker nodes:

```sh
cd scripts
./create-mint-eks-key.sh
```

This will create the key pair 'mint-eks-key' in AWS and save the private key to 'mint-eks-key.pem'. Keep this file secure and do not commit it to source control.

## Persistent Resources (Survive Destroy)
- ECR: `${var.project_name}-persistent-ecr` → Push private images
- S3:  `${var.project_name}-persistent-s3-<account>` and other S3 buckets

`terragrunt run --all destroy`  # ← Keeps ECR/S3 alive!

---

## Why Terraform over OpenTofu?

Terraform's Business Source License (BSL 1.1) is a source-available license applied to versions after 1.5.x, which 
allows internal use for your company's infrastructure stack without any cost or restrictions. It prohibits using 
Terraform as a hosted service or embedding it in competing commercial products without a special agreement from 
HashiCorp.

OpenTofu, being fully open-source, does not have these licensing restrictions, but at the time of this writing, it 
lacks the stability, features, and community support that Terraform has built over the years. For organizations needing 
a battle-tested solution with commercial support options, Terraform remains the preferred choice.
