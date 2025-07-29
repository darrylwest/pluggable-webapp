#!/usr/bin/env bash
# dpw@ubuntu-s-1vcpu-2gb-amd-sfo3-01-develop
# 2025.07.20
#

set -eu

file=./tmp/test-file.txt

cat $file | aws s3 cp - s3://rcs-develop/system/new-file.txt --endpoint-url https://sfo3.digitaloceanspaces.com
