terraform {
  backend "s3" {
    # Bucket, key, region, and dynamodb_table are provided via
    # partial configuration at `terraform init`:
    #
    #   terraform init \
    #     -backend-config="bucket=my-tfstate-bucket" \
    #     -backend-config="key=eks-gitops/terraform.tfstate" \
    #     -backend-config="region=us-gov-west-1" \
    #     -backend-config="dynamodb_table=terraform-locks"
    encrypt = true
  }
}
