# Batch Image Processing with Batch on GKE

### Create a GCS bucket
```
BUCKET_NAME=gs://batch-demo-bucket
gsutil mb -c Standard -l us-central1 $BUCKET_NAME
```
