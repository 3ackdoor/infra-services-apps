#!/bin/bash

. ./scripts/env-vars.sh

envsubst < module/nginx-ingress/overlays/alpha/nginx-ingress-service.yaml.tmpl > module/nginx-ingress/overlays/alpha/nginx-ingress-service.yaml
envsubst < module/nginx-ingress/overlays/alpha/cluster-admin-binding.yaml.tmpl > module/nginx-ingress/overlays/alpha/cluster-admin-binding.yaml
envsubst < module/argo-cd/overlays/alpha/nginx/argocd-ingress.yaml.tmpl > module/argo-cd/overlays/alpha/nginx/argocd-ingress.yaml
