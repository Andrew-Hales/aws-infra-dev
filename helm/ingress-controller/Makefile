# Makefile for deploying AWS Load Balancer Controller (Ingress Controller)

RELEASE_NAME ?= aws-load-balancer-controller
NAMESPACE ?= kube-system
CHART_REPO ?= eks
CHART_NAME ?= aws-load-balancer-controller
CHART_VERSION ?= 1.7.1
VALUES_FILE ?= values.yaml

.PHONY: add-repo
add-repo:
	helm repo add $(CHART_REPO) https://aws.github.io/eks-charts
	helm repo update

.PHONY: install
install: add-repo
	helm upgrade --install $(RELEASE_NAME) $(CHART_REPO)/$(CHART_NAME) \
	  --namespace $(NAMESPACE) \
	  --create-namespace \
	  --version $(CHART_VERSION) \
	  -f $(VALUES_FILE)

.PHONY: uninstall
uninstall:
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)

.PHONY: status
status:
	helm status $(RELEASE_NAME) --namespace $(NAMESPACE)

