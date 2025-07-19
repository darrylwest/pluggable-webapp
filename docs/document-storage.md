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

**Block Storage Advanages**

* Block storage is a familiar paradigm. People and software understand and support files and filesystems almost universally
* Block devices are well supported. Every programming language can easily read and write files
* Filesystem permissions and access controls are familiar and well-understood
* Block storage devices provide low latency IO, so they are suitable for use by databases.

**Block Storage Disadvantages**

* Storage is tied to one server at a time, no shared space
* Blocks and filesystems have limited metadata about the blobs of information they’re storing (creation date, owner, size). Any additional information about what you’re storing will have to be handled at the application and database level, which is additional complexity for a developer to worry about
* You need to pay for all the block storage space you’ve allocated, even if you’re not using it
* You can only access block storage through a running server
* Block storage needs more hands-on work and setup vs object storage (filesystem choices, permissions, versioning, backups, etc.)

### Spaces

Spaces, like S3 requires a support library, but there is a console to view buckets and files.  

**Spaces Advanages**

* A simple HTTP API, with clients available for all major operating systems and programming languages
* A cost structure that means you only pay for what you use
* Built-in public serving of static assets means one less server for you to run yourself
* Some object stores offer built-in CDN integration, which cache your assets around the globe to make downloads and page loads faster for your users
* Optional versioning means you can retrieve old versions of objects to recover from accidental overwrites of data
* Object storage services can easily scale from modest needs to really intense use-cases without the developer having to launch more resources or rearchitect to handle the load
* Using an object storage service means you don’t have to maintain hard drives and RAID arrays, as that’s handled by the service provider
* Being able to store chunks of metadata alongside your data blob can further simplify your application architecture

**Spaces Disadvantages**

* You can’t use object storage services to back a traditional database, due to the high latency of such services.  but may work in our case because we cache everything.  with a custom data router we could easily cache a 10 to 12 months of data and archive the rest.
* Object storage doesn’t allow you to alter just a piece of a data blob, you must read and write an entire object at once. This has some performance implications. For instance, on a filesystem, you can easily append a single line to the end of a log file. On an object storage system, you’d need to retrieve the object, add the new line, and write the entire object back. This makes object storage less ideal for data that changes very frequently
* Operating systems can’t easily mount an object store like a normal disk. There are some clients and adapters to help with this, but in general, using and browsing an object store is not as simple as flipping through directories in a file browser

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
