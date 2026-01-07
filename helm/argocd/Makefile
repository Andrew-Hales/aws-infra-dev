HELM ?= helm
NAMESPACE ?= argocd
RELEASE ?= argocd
VALUES ?= values.yaml

.PHONY: install uninstall upgrade status port-forward

install:
	$(HELM) repo add argo https://argoproj.github.io/argo-helm
	$(HELM) repo update
	$(HELM) upgrade --install $(RELEASE) argo/argo-cd \
	  --namespace $(NAMESPACE) --create-namespace \
	  -f $(VALUES)

uninstall:
	$(HELM) uninstall $(RELEASE) --namespace $(NAMESPACE)

upgrade:
	$(HELM) upgrade $(RELEASE) argo/argo-cd \
	  --namespace $(NAMESPACE) -f $(VALUES)

status:
	$(HELM) status $(RELEASE) --namespace $(NAMESPACE)

port-forward:
	kubectl port-forward svc/$(RELEASE)-server -n $(NAMESPACE) 8080:80

