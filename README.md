# Batch Image Processing with Batch on GKE

### Create a GCS bucket
```
BUCKET_NAME=gs://batch-demo-bucket
gsutil mb -c Standard -l us-central1 $BUCKET_NAME
```
### Create a Filestore instance
```
gcloud filestore instances create batch-filestore \
--zone=us-central1-a \
--file-share-name=fileshare 
```
