# OpenTofu - Cloudflare

![OpenTofu compatibility](https://img.shields.io/badge/OpenTofu-Compatible-FFDA18?logo=opentofu&logoColor=white)

```bash
# export CLOUDFLARE_R2_STORAGE_AWS_ACCESS_KEY_ID="d7xxxxxd5"
export AWS_ACCESS_KEY_ID="d7xxxxxd5"
# export CLOUDFLARE_R2_STORAGE_AWS_SECRET_ACCESS_KEY="35xxxx07e"
export AWS_SECRET_ACCESS_KEY="35xxxx07e"
# export CLOUDFLARE_R2_STORAGE_AWS_ENDPOINT_URL_S3="https://b3xxxxx50.r2.cloudflarestorage.com"
export AWS_S3_ENDPOINT="https://b3xxxxx50.r2.cloudflarestorage.com"
echo "*** ${AWS_ACCESS_KEY_ID} | ${AWS_SECRET_ACCESS_KEY} | ${AWS_S3_ENDPOINT}"

tofu init
tofu apply
```
