# scripts/Makefile

PROJECT    ?= poc-eks-openvpn
TF_DIR     ?= ../terraform
TF         ?= terraform
AWS_REGION ?= us-east-1
TFVARS_FILE ?= ../configuration/dev.tfvars
BACKEND_CONFIG ?= ../configuration/backend-dev.conf
TG := terragrunt
REGION     ?= us-east-1
TG_DIR    ?= ../live/$(REGION)/dev

# Helper: run terraform in the TF_DIR
define TF_CMD
	cd $(TF_DIR) && $(TF) $(1)
endef

.PHONY: init fmt validate plan apply destroy output kubeconfig install-alb-controller deploy-test-app full-poc help

init:
	cd $(TG_DIR) && $(TG) run --all init

fmt:
	$(call TF_CMD,fmt -recursive)

validate: fmt
	$(call TF_CMD,validate)

plan: validate
	cd $(TG_DIR) && $(TG) run --all plan

apply: validate
	cd $(TG_DIR) && $(TG) run --all apply

destroy:
	cd $(TG_DIR) && $(TG) run --all destroy

output:
	cd $(TG_DIR) && $(TG) run --all output

kubeconfig:
	aws eks update-kubeconfig --name $(PROJECT)-cluster --region $(AWS_REGION)

install-alb-controller:
	./install-alb-controller.sh

deploy-test-app:
	./deploy-test-app.sh

# Full PoC workflow
full-poc: apply kubeconfig install-alb-controller deploy-test-app
	@echo "✅ PoC ready! Connect via OpenVPN and curl hello.poc.internal"

help:
	@echo "Available commands:"
	@echo "  make init                 - Initialize Terragrunt in all modules"
	@echo "  make fmt                  - Format Terraform code recursively"
	@echo "  make validate             - Validate Terraform configuration"
	@echo "  make plan                 - Show Terragrunt execution plan for all modules"
	@echo "  make apply                - Apply Terragrunt changes for all modules"
	@echo "  make destroy              - Destroy Terragrunt-managed infrastructure for all modules"
	@echo "  make output               - Show Terragrunt outputs for all modules"
	@echo "  make kubeconfig           - Update kubeconfig for EKS cluster"
	@echo "  make install-alb-controller - Install AWS Load Balancer Controller via Helm"
	@echo "  make deploy-test-app      - Deploy test application to EKS"
	@echo "  make full-poc             - Run full PoC workflow (apply, kubeconfig, ALB controller, test app)"
