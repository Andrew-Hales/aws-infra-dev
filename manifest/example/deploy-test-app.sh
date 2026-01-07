#!/bin/bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello
        image: paulbouwkamp/hello-world-rest-api:latest
        ports:
        - containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: hello-service
  namespace: default
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # Optional NLB for backend
spec:
  selector:
    app: hello
  ports:
  - port: 80
    targetPort: 8000
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-ingress
  namespace: default
  annotations:
    alb.ingress.kubernetes.io/scheme: internal  # PRIVATE ALB only!
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/security-groups: $(terraform -chdir=../terraform/ output -raw alb_internal_sg_id)
spec:
  ingressClassName: alb
  rules:
  - host: "hello.poc.internal"  # Your private domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-service
            port:
              number: 80
EOF

echo "ALB DNS: $(kubectl get ingress hello-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "Access via OpenVPN: curl hello.poc.internal (from VPN client)"
