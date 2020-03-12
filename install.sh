#!/bin/bash
# Copyright 2017 Google LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
CLUSTER_NAME="hello-batch"
PROJECT="qwiklabs-gcp-04-58f1a5785d67"
ZONE="us-central1-a"
REGION="us-central1"
gcloud auth login
gcloud auth application-default login
read -p "Please type in your username in this GCP project (example: alice@example.com): " USER
gcloud beta container clusters create $CLUSTER_NAME \
    --region $REGION \
    --node-locations $ZONE \
    --num-nodes 1 \
    --machine-type n1-standard-8 \
    --release-channel regular \
    --enable-stackdriver-kubernetes \
    --identity-namespace=${PROJECT}.svc.id.goog \
    --enable-ip-alias
gcloud iam roles create BatchUser --project $PROJECT \
--title GKEClusterReader --permissions container.clusters.get --stage BETA 2>&1
kubectl create clusterrolebinding cluster-admin-binding-${USER} \
--clusterrole=cluster-admin --user $USER
gcloud iam service-accounts create kbatch-controllers-gcloud-sa --display-name \
kbatch-controllers-gcloud-service-account
kubectl create serviceaccount --namespace kube-system kbatch-controllers-k8s-sa
gcloud projects add-iam-policy-binding $PROJECT \
--member serviceAccount:kbatch-controllers-gcloud-sa@${PROJECT}.iam.gserviceaccount.com \
--role=roles/container.clusterAdmin
gcloud projects add-iam-policy-binding $PROJECT \
--member serviceAccount:kbatch-controllers-gcloud-sa@${PROJECT}.iam.gserviceaccount.com \
--role=roles/compute.admin
gcloud projects add-iam-policy-binding $PROJECT \
--member serviceAccount:kbatch-controllers-gcloud-sa@${PROJECT}.iam.gserviceaccount.com \
--role=roles/iam.serviceAccountUser
gcloud iam service-accounts add-iam-policy-binding \
--role roles/iam.workloadIdentityUser \
--member "serviceAccount:${PROJECT}.svc.id.goog[kube-system/kbatch-controllers-k8s-sa]" kbatch-controllers-gcloud-sa@${PROJECT}.iam.gserviceaccount.com
kubectl annotate serviceaccount --namespace kube-system kbatch-controllers-k8s-sa \
iam.gke.io/gcp-service-account=kbatch-controllers-gcloud-sa@${PROJECT}.iam.gserviceaccount.com
wget https://github.com/GoogleCloudPlatform/Kbatch/raw/master/releases/kbatch-0.7.1.tar.gz
tar -xvzf kbatch-0.7.1.tar.gz
cd kbatch
sed -i "s/<k8s-cluster-name>/$CLUSTER_NAME/g" config/kbatch-config.yaml
sed -i "s/<k8s-cluster-region>/$REGION/g" config/kbatch-config.yaml
sed -i "s/<kbatch-project-id>/$PROJECT/g" config/kbatch-config.yaml
sed -i "s/<k8s-cluster-node-zone>/$ZONE/g" config/kbatch-config.yaml
kubectl create configmap --from-file config/kbatch-config.yaml -n kube-system kbatch-config
gcloud compute machine-types list --filter="zone:${ZONE}" --format json > ./machine_types.json
kubectl create configmap --from-file ./machine_types.json -n kube-system kbatch-machine-types
kubectl apply -f install/01-crds.yaml
kubectl apply -f install/02-admission.yaml
kubectl apply -f install/03-controller.yaml
