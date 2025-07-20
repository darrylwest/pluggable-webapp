#!/usr/bin/env bash
# dpw@ubuntu-s-1vcpu-2gb-amd-sfo3-01-develop
# 2025.07.20
#

set -eu

for bucket in rcs-document-store rcs-database
do
    echo $bucket
    aws s3 ls s3://$bucket/ --endpoint-url https://sfo3.digitaloceanspaces.com
    echo "__________________________________________________"

done

