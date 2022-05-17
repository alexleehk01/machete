#!/bin/bash
# split terraformer generated file by resource

export terraformer_import_arguments=""
# example: "aws --resources=cloudfront --profile=prod"
export terraformer_generated_path=""
# example: "generated/aws/cloudfront/cloudfront_distribution.tf"

# remove existing files
rm -rf .terraform .terraform.lock.hcl generated splitted_resources

# import resources using terraformer
terraform init
terraformer import $terraformer_import_arguments

# split the generated tf by resource
mkdir splitted_resources
pushd splitted_resources
csplit -z -s -f '' -b %03d.tf ../$terraformer_generated_path '/resource /' '{*}'
popd
