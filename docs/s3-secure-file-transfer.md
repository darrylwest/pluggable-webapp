# S3 Secure File Transer

This document shows how we 

## Sending data to s3/spaces:

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│   Source    │───▶│   Encrypt    │───▶│   AWS CLI   │───▶│ DO Spaces   │
│    Data     │    │ AES-256-GCM  │    │     cp      │    │   Bucket    │
└─────────────┘    └──────────────┘    └─────────────┘    └─────────────┘

```

* **source data** might be a file or it could by the output of a web-socket data transfer
* encryption is done with sodium in an executable called salt-pipe
* aws cli is used to do the actual transfer from the droplet to s3
* the destination is an ecrypted file in the designated bucket and folder with an extension of `.enc` (encoded)

## Reading data fro s3/spaces

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│ DO Spaces   │───▶│   AWS CLI    │───▶│   Decrypt   │───▶│ Destination │
│   Bucket    │    │     cp       │    │ AES-256-GCM │    │    Data     │
└─────────────┘    └──────────────┘    └─────────────┘    └─────────────┘
```

* the data source is an ecrypted file in the designated bucket and folder with an extension of `.enc`
* aws cli is used to do the actual transfer from s3 to the droplet
* encryption is done with sodium in an executable called salt-pipe
* The destination data might be a file or it could by the input of a web-socket data transfer

## Solt Pipe

* reads the encryption key from .env using dotenvx
* reads from `stdin` and either encrypts or decrypts then writes to `stdout`

### Example use:

###### dpw | 2025.07.26



