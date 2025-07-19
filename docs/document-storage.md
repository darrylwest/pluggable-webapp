# Document Storage

## Tasks

* Plan how to use S3 type buckets (spaces) on digital ocean through typescript to store encrypted documents.  
* Determine how the web UI can transfer files from client machine to document storage.
* Consider alternatives.

## Block Storage vs S3 Spaces

### Block Storage 

Block storage is like an extended file system.  It's encrypted, so safe for HIPAA and since it's just a filesystem,
no new libraries are involved.  It's also fast enough to use as a data store. It uses Ceph Volume Block security.

Another advantage is the ability to mount the storage from different droplet instances, although one at a time. 
This simplifies complete upgrades by retaining the data while droplets are taken down and brought back up.

List of advanages

* Block storage is a familiar paradigm. People and software understand and support files and filesystems almost universally
* Block devices are well supported. Every programming language can easily read and write files
* Filesystem permissions and access controls are familiar and well-understood
* Block storage devices provide low latency IO, so they are suitable for use by databases.

Disadvantages

* Storage is tied to one server at a time, no shared space
* Blocks and filesystems have limited metadata about the blobs of information they’re storing (creation date, owner, size). Any additional information about what you’re storing will have to be handled at the application and database level, which is additional complexity for a developer to worry about
* You need to pay for all the block storage space you’ve allocated, even if you’re not using it
* You can only access block storage through a running server
* Block storage needs more hands-on work and setup vs object storage (filesystem choices, permissions, versioning, backups, etc.)

### Spaces

Spaces, like S3 requires a support library, but there is a console to view buckets and files.  


## Alternatives

### Google Cloud Storage

* google cloud storage for pricing. $4.90 / m 250 GiB
* [google cloud storage docs](https://cloud.google.com/solutions/healthcare-life-sciences?hl=en)
* not S3 command compatible, so requires new libs

## Conclusions

It would be easier (but more expensive) to use block storage.  The pricing is $0.10 per Gig compared to 250G for $5.00 / month;

### References

[Digital Ocean Discussion](https://www.digitalocean.com/community/tutorials/object-storage-vs-block-storage-services)

###### dpw | 2025.07.19
