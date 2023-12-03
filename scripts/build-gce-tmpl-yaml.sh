#!/bin/bash

. ./scripts/env-vars.sh

envsubst < module/argo-cd/overlays/alpha/gce/argocd-cert.yaml.tmpl > module/argo-cd/overlays/alpha/gce/argocd-cert.yaml
envsubst < module/argo-cd/overlays/alpha/gce/argocd-iap-oauth-client.yaml.tmpl > module/argo-cd/overlays/alpha/gce/argocd-iap-oauth-client.yaml
envsubst < module/argo-cd/overlays/alpha/gce/argocd-ingress.yaml.tmpl > module/argo-cd/overlays/alpha/gce/argocd-ingress.yaml
