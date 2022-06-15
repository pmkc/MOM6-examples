#!/bin/bash

PROJECT=$(gcloud config get-value project)
BUCKET=pclay-public
IMAGE=us.gcr.io/$PROJECT/mom6
docker build -t $IMAGE .
docker push $IMAGE
gsutil cp mom6_postinit.sh gs://$BUCKET
gcloud notebooks instances create mom6 \
    --location us-east1-b \
    --container-repository=$IMAGE \
    --post-startup-script=gs://$BUCKET/mom6_postinit.sh \
    "$@"
