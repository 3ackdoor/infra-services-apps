#!/bin/bash

export INGRESS_STATIC_IP=$(gcloud compute addresses describe argocd-ingress-static-ip --region asia-southeast1 --format="get(address)")
export YOURDOMAIN_COM=
export OAUTH_CLIENT_ID=
export OAUTH_CLIENT_SECRET=
export SERVICE_ACCOUNT=$(gcloud config get-value account)