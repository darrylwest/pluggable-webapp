# Droplet Security Procedures

## Overview

**Start with this premise** _Any secret key or other sensitive customer data stored un-encrypted on disk poses a significant security risk._ 

**Here is why...**

While DigitalOcean's **snapshots** are private to your account and encrypted at rest on their backend, embedding secret keys directly into the image (and thus, the snapshot) creates several layers of risk. The problem isn't with the snapshot feature itself, but with the underlying practice of storing secrets on the filesystem. The snapshot simply copies and perpetuates this risk.

Here’s a detailed breakdown of why it's a security risk.

### The Security Risks Explained

#### 1. Risk of Exposure and Unauthorized Access

*   **Compromised DigitalOcean Account:** If an attacker gains access to your DigitalOcean account credentials, they don't need to access your live server. They can simply create a new Droplet from your snapshot, boot it up, and have full root access to a perfect clone of your server, including all the secret keys stored on it. This is the most direct and severe risk.
*   **Accidental Sharing:** You might share a snapshot with a team member, a contractor, or even another DigitalOcean account for legitimate reasons. When you do this, you are also handing them a copy of all your embedded secrets. If that person's account is compromised or their access is not properly revoked later, your keys are exposed.
*   **Internal Threats:** A disgruntled employee or a team member with access to the DigitalOcean console could access the snapshots and extract sensitive information without ever touching the production Droplet, potentially going undetected by your server's monitoring tools.

#### 2. Secret Management and Rotation Issues

*   **Stale Secrets:** When you rotate a secret key (e.g., change a database password or an API key) on your live Droplet, the old, deprecated key still exists within all your previous snapshots. If you ever restore an old snapshot in an emergency, you will be restoring an old, potentially compromised key, which could cause application failures or re-introduce a security vulnerability.
*   **Lack of a Single Source of Truth:** You now have keys scattered across your live Droplet and potentially dozens of snapshots. It becomes impossible to audit who has access to which keys and which keys are currently active. This is a management nightmare.
*   **Difficult to Revoke:** If a key is compromised, you not only need to change it on the live server but also must consider all snapshots that contain it as "tainted." The only way to be truly safe is to delete all snapshots containing the compromised key, which may conflict with your backup and disaster recovery policies.

#### 3. Compliance and Best Practice Violations

*   **Violates the Principle of Least Privilege:** Secrets should only be accessible at the moment they are needed, by the process that needs them. Storing them on the filesystem makes them broadly available to any process or user with sufficient read permissions on the server.
*   **Security Anti-Pattern:** Storing secrets in code or configuration files on an image is a well-known security anti-pattern. Modern infrastructure practices strongly advocate for externalizing configuration and secrets.
*   **Audit and Compliance Failures:** If your company needs to comply with standards like **PCI-DSS, SOC 2, or HIPAA**, this practice would almost certainly be flagged as a major finding during an audit. These frameworks have strict requirements for secret and key management.

---

### Best Practices for Droplet Snapshots

The goal is to create "clean" or "immutable" images that do not contain any secrets. The secrets will be provided to the Droplet at runtime.

#### 1. Externalize Secrets

Instead of storing secrets on the image, use a dedicated secret management tool. The application on your Droplet will then securely fetch these secrets when it starts up.

**Recommended Solutions:**

*   **HashiCorp Vault:** The industry standard for secret management. It's a powerful tool for centrally storing, securing, and controlling access to secrets. Your application would authenticate with Vault (using a token or AppRole) to retrieve what it needs at runtime.
*   **Cloud-Init and User Data:** This is a good "better than nothing" approach available directly in DigitalOcean. You can pass the secrets to the Droplet through the "User Data" field during creation. Your cloud-init script can then place these secrets into environment variables or temporary files for your application to consume.
    *   **Caveat:** The User Data is visible in the DigitalOcean control panel, so it's still not as secure as a dedicated secrets manager, but it's far better than baking them into the snapshot.
*   **Environment Variables:** Configure your application to read secrets from environment variables. You can then use a process manager (like `systemd`) or a script to inject these variables when the application process starts. The variables themselves can be supplied via User Data or pulled from a secure location.

#### 2. A Recommended Workflow

1.  **Remove Secrets:** Go through your codebase and configuration files on your Droplet and remove every hardcoded secret key, password, and API token.
2.  **Choose a Secrets Store:** Set up a secrets manager like HashiCorp Vault.
3.  **Modify Your Application:** Update your application to read its configuration from environment variables or to query your chosen secrets manager at startup.
4.  **Create a "Clean" Base Image:** Now that the image is free of secrets, take a snapshot. This is your new "golden image."
5.  **Automate Provisioning:** When you create a new Droplet from this snapshot, use the **User Data** field to run a startup script (cloud-init). This script's job is to:
    *   Install any final dependencies.
    *   Fetch the secrets from your secrets manager (e.g., Vault).
    *   Export them as environment variables.
    *   Start your application.

### Snapshot Conclusion

**A snapshot of an image containing secret keys is a copy of a security liability.**

By separating our secrets from our application image, our snapshots become safe backups of application logic and operating system configuration, not ticking time bombs of sensitive data. This makes our infrastructure more secure, manageable, and compliant with modern best practices.

----

## S3 / Spaces Storage

**Never store unencrypted sensitive data in DigitalOcean Spaces (or any S3-compatible object storage).**

While DigitalOcean provides its own layers of security, relying solely on them is a dangerous practice that has led to countless data breaches across all cloud providers. The principle is the same as with the snapshots: you are responsible for the security of your data *within* the service.

Let's break down why and how to secure your data in Spaces.

### The Risks of Storing Unencrypted Data in Object Storage

DigitalOcean automatically encrypts all data stored in Spaces **at rest** on their physical disks (Server-Side Encryption or SSE). They also enforce **encryption in transit** via HTTPS (TLS).

So, if it's encrypted at rest and in transit, what's the risk?

The risk lies in the **access layer**. The server-side encryption only protects against someone physically stealing a hard drive from a DigitalOcean data center. It does **not** protect your data from being accessed via a legitimate (or stolen) API key.

Here are the primary threats:

1.  **Misconfigured Permissions (The #1 Cause of Breaches):** The most common reason for object storage data leaks is accidentally setting a bucket (a Space) or individual files to "Public." If your sensitive data is unencrypted, anyone on the internet who finds the URL can download it.
2.  **Compromised Access Keys:** This is the most direct threat. If an attacker steals your Spaces access keys—from a public GitHub repository, a misconfigured CI/CD pipeline, a developer's laptop, or a compromised server—they can use those keys to list, download, and modify all the unencrypted data in your Spaces. DigitalOcean's encryption at rest is irrelevant here, because the service will happily decrypt the data for anyone presenting valid keys.
3.  **Application Vulnerabilities:** A vulnerability in your application (like Server-Side Request Forgery - SSRF) could be exploited by an attacker to make your server fetch and expose files from your Space, even if the Space itself is private. If the data is unencrypted, it's immediately compromised.
4.  **Insider Threats:** A malicious or careless employee with valid access keys could access and leak data. Client-side encryption mitigates this by ensuring that even someone with access to the storage bucket cannot read the file contents without a separate decryption key.

### The Solution: Client-Side Encryption

The gold standard for securing data in object storage is **client-side encryption**.

This means **you encrypt the data *before* you upload it to DigitalOcean Spaces.**

When you do this, the files sitting in your Space are just meaningless encrypted blobs. DigitalOcean never sees the unencrypted data, and an attacker who steals your Spaces access keys gets nothing of value without also stealing your separate encryption keys.

#### How to Implement Client-Side Encryption:

1.  **Using Application Libraries (Recommended):** Most programming languages have S3-compatible libraries that can handle this for you. For example, the AWS SDKs (which are compatible with Spaces) have built-in support for client-side encryption. You provide the library with a master key, and it handles the encryption/decryption transparently.
    *   **Python:** Use `boto3` with a client-side encryption handler.
    *   **Node.js:** Use the `@aws-sdk/client-s3` with encryption extensions.
    *   **Go:** Use the official AWS SDK for Go.
2.  **Manual Encryption:** For less frequent uploads, you can encrypt files manually before uploading them using tools like `GPG` or `openssl`. This is more cumbersome for an application but works for backups or manual archival.

**The most critical part of this strategy is managing the encryption keys.** These keys should be treated with the same high level of security as the database passwords and API keys from your first question. They should be stored in a secure secrets manager like **HashiCorp Vault**.

### Best Practices for DigitalOcean Spaces Security

Here is a checklist to follow:

| Practice | Why it's Important |
| :--- | :--- |
| **1. Use Client-Side Encryption** | This is your strongest defense. It ensures that even if your Space is compromised, your data remains unreadable. |
| **2. Keep Spaces Private** | By default, Spaces and their files are private. **Never** make a Space public unless you are 100% certain it only contains non-sensitive, public-facing assets (like website images or CSS). |
| **3. Use the Principle of Least Privilege for Keys** | Create different access keys for different purposes. If an application only needs to *write* to a Space, create a key that only has `s3:PutObject` permission and not `s3:GetObject` or `s3:DeleteObject`. |
| **4. Do Not Hardcode Keys** | Never put your Spaces access keys directly in your code. Load them from environment variables or a secrets management tool at runtime. |
| **5. Rotate Your Access Keys** | Periodically rotate your access keys to limit the window of opportunity for an attacker if a key is ever exposed. |

### Conclusion

Think of it this way:

*   **DigitalOcean's Server-Side Encryption** is like the locked door on the warehouse where your valuables are stored. It protects against someone breaking into the building.
*   **Client-Side Encryption** is like putting your valuables inside a personal, locked safe *before* you even put them in the warehouse.

We need both. An attacker who picks the lock on the warehouse door (steals our API keys) still can't get into our personal decrypted  data.

In short: **Treat DigitalOcean Spaces as a secure vault for *encrypted* data, not as a secure vault for *unencrypted* data.**
###### dpw | 2025.07.23
