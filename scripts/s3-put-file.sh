#!/usr/bin/env bash
# dpw@ubuntu-s-1vcpu-2gb-amd-sfo3-01-develop
# 2025.07.20
#

set -eu

file=test-file.txt

aws s3 cp ./tmp/$file s3://rcs-document-store/$file --endpoint-url https://sfo3.digitaloceanspaces.com
