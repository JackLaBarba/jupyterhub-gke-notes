# From https://zero-to-jupyterhub.readthedocs.io/en/latest/google/step-zero-gcp.html

ZONE=
CLUSTERNAME=
GCPPROJECT=
GOOG_EMAIL_ACCOUNT=

# Set up GKE
gcloud config set project $GCPPROJECT

gcloud container clusters create \
  --machine-type n1-standard-2 \
  --num-nodes 2 \
  --zone $ZONE \
  --cluster-version latest \
  $CLUSTERNAME

kubectl get node

kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$GOOG_EMAIL_ACCOUNT

# Set up Helm
kubectl --namespace kube-system create serviceaccount tiller

kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

helm init --service-account tiller --history-max 100 --wait

kubectl patch deployment tiller-deploy --namespace=kube-system --type=json --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'

helm version

# set up jupyterhub
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/

helm repo update

RELEASE=jhub
NAMESPACE=jhub

helm upgrade --install $RELEASE jupyterhub/jupyterhub \
  --namespace $NAMESPACE  \
  --version=0.8.2 \
  --values config.yaml

kubectl config set-context $(kubectl config current-context) --namespace ${NAMESPACE:-jhub}

# get public IP
kubectl get service --namespace jhub

# deploy config changes
helm upgrade $RELEASE jupyterhub/jupyterhub \
  --version=0.8.2 \
  --values config.yaml \
  --timeout=600