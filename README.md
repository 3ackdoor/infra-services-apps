# Infra Services Apps

## Prerequisites

```bash
# Clone argocd project from official repo at the same directory path level as infra-services-apps (change directory out of this infra-services-apps)
git clone -b v2.8.4 https://github.com/argoproj/argo-cd.git
```

## Steps to repeat every startup of Workstation VM (Manual)

```bash
eval $(ssh-agent) &&

gcloud secrets versions access 1 --secret="SSH_PRIVATE_KEY_LOCAL_CONTROL_PLANE" --project=gitops-learning01 | ssh-add - >/dev/null &&

gcloud secrets versions access 1 --secret="GCP_CREDS_LOCAL_CONTROL_PLANE" --project=gitops-learning01 --out-file=/home/user/.config/gcloud/root-ca.json >/dev/null &&

git config --global --replace-all user.email "anewnursery@gmail.com" &&
git config --global --replace-all user.name "Anew Eiamsuwansai" &&

minikube start &&

gcloud auth activate-service-account root-ca@gitops-learning01.iam.gserviceaccount.com --key-file=/home/user/.config/gcloud/root-ca.json &&

yes | gcloud config set project gitops-learning01 &&

gcloud container clusters get-credentials gl-alpha-private-controller-cluster-0 --zone asia-southeast1-b --project gitops-learning01 &&

gcloud container clusters update gl-alpha-private-controller-cluster-0 --zone asia-southeast1-b --enable-master-authorized-networks --master-authorized-networks $(gcloud compute instances describe "$(gcloud compute instances list | grep local-control-plane-ws-config | awk '{print $1}')" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')/32
```

## Instruction (NGINX)

```bash

# Update `./scripts/env-vars.sh` -> `YOURDOMAIN_COM`
vi ./scripts/env-vars.sh

# Create Static IP (skip this if you have already done this before)
gcloud compute addresses create argocd-ingress-static-ip --region asia-southeast1

# Replace with env variables with envsubst
./scripts/build-nginx-tmpl-yaml.sh

# Install ArgoCD with NGINX-Ingress
kubectl apply -k module/argo-cd/overlays/alpha/nginx
```

## Instruction (GCE)

### Configure a new OAuth Client ID

- Go to [Google API Credentials](https://console.cloud.google.com/apis/credentials)
- Click on `+ CREATE CREDENTIALS` and select `OAuth client ID`

- To create an OAuth client ID, you must first configure your consent screen
  - Click on `CONFIGURE CONSENT SCREEN`
  - Select `Internal` if you're using organization email or select `External` if you're using your personal email. (In this tutorial, I choose `External`)
  - Complete `OAuth consent screen` section
    - Fill `App name` with `argocd`
    - Use your current email for `User support email`
    - Add the `Authorized Domains` which are authorized to log into the ArgoCD
    - Use your current email for `Developer contact information`
    - Click on `SAVE AND CONTINUE` to `Scopes` section
  - Complete `Scopes` section
    - Click on `ADD OR REMOVE SCOPES`
    - Add `.../auth/userinfo.profile` and `openid` scopes then click on `UPDATE`
    - Click on `SAVE AND CONTINUE` to `Test users` section
  - Complete `Test users` section
    - Click on `+ ADD USERS`
    - Type your current Google email address then Click on `ADD`
    - Click on `SAVE AND CONTINUE` to `Summary` section
  - On `Summary` section
    - Check your configuration and edit any if you want
    - Click on `BACK TO DASHBOARD`

- Repeat step 1-2
- Select the `Application Type` as `Web application` and give a `Name` as `argocd`
- Fill `Authorized JavaScript origins` with your desired ArgoCD URL. In this case, just will with `https://argocd.YOURDOMAIN.com` (replace `YOURDOMAIN` with your domain name) and also replace value in `scripts/env-vars.sh`
- Fill `Authorized redirect URIs` with your ArgoCD URL + /api/dex/callback (e.g. `https://argocd.YOURDOMAIN.com/api/dex/callback`)
- Click on `CREATE` and get `Client ID` and `Client secret` and replace the values in `scripts/env-vars.sh`

```bash
# Create Global Static IP (for future use)
gcloud compute addresses create argocd-ingress-static-ip  --global --ip-version IPV4

# Replace with env variables with envsubst
./scripts/build-gce-tmpl-yaml.sh

# Install ArgoCD with GCE
kubectl apply -k module/argo-cd/overlays/alpha/gce 
```

## Optional steps (don't bother, I just noted for myself)

```bash
################
### Optional ###
################
# Watch status for argocd-server pod
kubectl -n argocd rollout status deployment argocd-server

# Forward port for argocd-server in the background (completely detach from terminal)
# PS. to kill the background process, use `killall -9 kubectl`.
nohup kubectl port-forward -n argocd svc/argocd-server 8080:80 </dev/null >/dev/null 2>&1 &

# Echo the forwarded port with localhost and open the link by click the url to open the Google Cloud Workstations forwarded url
# Then you will be forwarded to ArgoCD login UI on web browser
# [For example `http://localhost:8080](https://8080-local-control-plane-ws.cluster-xxxxxxxxxxxxx.cloudworkstations.dev/)`
echo http://localhost:8080

# Download and install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Retrieve the initial password for the admin account in a secret named "argocd-initial-admin-secret"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Login to the ArgoCD
argocd --port-forward --port-forward-namespace=argocd --grpc-web --plaintext login --username=admin --password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)

# Change the password (you will be prompted to enter the new password)
# For example, we will use "123456789" as the new password (don't do this on production, just use your own password)
argocd --port-forward --port-forward-namespace=argocd --grpc-web --plaintext account update-password --current-password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)
```

## References

<https://gist.github.com/vfarcic/fca66711eaf0440483eba42ee013311a>
<https://stackoverflow.com/questions/61365202/nginx-ingress-service-ingress-nginx-controller-admission-not-found/62044090#62044090>
<https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#google-cloud-load-balancers-with-kubernetes-ingress>
<https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#kubernetesingress-nginx>
<https://medium.com/@tharukam/configuring-argo-cd-on-gke-with-ingress-iap-and-google-oauth-for-rbac-a746fd009b78>
<https://kubernetes.github.io/ingress-nginx/deploy/#gce-gke:~:text=For%20private%20clusters,for%20more%20detail.>
<https://stackoverflow.com/questions/48763805/does-gke-support-nginx-ingress-with-static-ip>
<https://medium.com/@megaurav25/argocd-ingress-setup-fc2929fc107e>
<https://www.youtube.com/watch?v=LYBGBuaOH8E>
<https://cert-manager.io/docs/tutorials/acme/nginx-ingress/>
