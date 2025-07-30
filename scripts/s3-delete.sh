#!/usr/bin/env bash
# dpw@larkspur.localdomain
# 2025-07-26 16:22:27
#

set -eu

aws s3 rm s3://rcs-develop/system/new-file.txt --endpoint-url https://sfo3.digitaloceanspaces.com

