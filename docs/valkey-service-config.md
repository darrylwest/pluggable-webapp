# Valkey Service Config

Running multiple instances of Valkey on a single machine is a common requirement for separating environments (dev, staging), isolating customer data, or for different application caches. The best practice for a production solution on a modern Ubuntu system like 24.10 is to use `systemd` template units.

This approach is robust, scalable, and aligns with standard system administration practices on Linux.

Here is a complete, step-by-step guide to setting up a production-ready multi-instance Valkey environment.

---

### Overview of the Solution

We will create a `systemd` template unit file named `valkey-server@.service`. The `@` symbol allows us to start, stop, and manage different instances by passing an "instance identifier" (which we'll use for the port number).

For example, to manage the Valkey instance on port `6379`, we will use commands like:
`systemctl start valkey-server@6379.service`

This single template file will manage all our Valkey instances, each with its own isolated configuration, data directory, and log file.

---

### Step 1: Install Valkey

First, ensure Valkey is installed on your Ubuntu 24.10 system. The recommended way is to use the official PPA maintained by the Valkey project.

```bash
# Add the Valkey PPA
sudo apt-add-repository ppa:valkey-db/valkey
sudo apt update

# Install the server and command-line tools
sudo apt install valkey-server valkey-tools
```

### Step 2: Prepare the Directory Structure and Disable Default Service

The default installation provides a single service file (`valkey-server.service`). We need to disable it because we'll be using our own template. We also need to create a clean directory structure to hold our instance-specific files.

1.  **Disable the default service:**

    ```bash
    sudo systemctl stop valkey-server
    sudo systemctl disable valkey-server
    ```

2.  **Create directories for instance configurations:**

    We will store our custom configurations in a separate directory to avoid conflicts with package updates.

    ```bash
    sudo mkdir -p /etc/valkey/instances
    ```

3.  **Create directories for instance data:**

    Each instance needs its own data directory. We'll name them by port number for clarity. Let's assume we're creating instances for ports `6379` and `6380`.

    ```bash
    sudo mkdir -p /var/lib/valkey/6379
    sudo mkdir -p /var/lib/valkey/6380
    ```

### Step 3: Create the `systemd` Template Unit File

Now, we'll create our master template file. This file tells `systemd` how to launch any given instance of Valkey. The `%i` specifier is a placeholder that will be replaced by the instance identifier (e.g., "6379").

Create the file `/etc/systemd/system/valkey-server@.service`:

```bash
sudo nano /etc/systemd/system/valkey-server@.service
```

Paste the following content into the file:

```ini
[Unit]
Description=Valkey In-Memory Data Store (Instance @%i)
After=network.target
Documentation=https://valkey.io/docs/

[Service]
Type=notify
User=valkey
Group=valkey
ExecStart=/usr/bin/valkey-server /etc/valkey/instances/%i.conf --supervised systemd
ExecStop=/usr/bin/valkey-cli -p %i shutdown
Restart=always
# Specifies the directory Valkey can write a PID file to
RuntimeDirectory=valkey

[Install]
WantedBy=multi-user.target
```

**Explanation of key directives:**

*   `Description=... (Instance @%i)`: Gives each service a descriptive name in `systemctl status`.
*   `ExecStart=... /etc/valkey/instances/%i.conf`: This is the core of the template. It launches `valkey-server` using the configuration file that matches the instance identifier (e.g., `/etc/valkey/instances/6379.conf`).
*   `--supervised systemd`: Critical for robust integration. Valkey will signal `systemd` when it's ready.
*   `ExecStop=... -p %i shutdown`: Provides a clean way to shut down the specific instance.
*   `User=valkey`, `Group=valkey`: Runs the process under the dedicated `valkey` user for security.
*   `RuntimeDirectory=valkey`: Asks `systemd` to create and manage `/run/valkey` for us, which is where PID files will go.

### Step 4: Create Instance Configuration Files

Now, create a configuration file for each instance inside `/etc/valkey/instances/`.

#### Instance 1: Port 6379

1.  Create the config file `6379.conf`:

    ```bash
    sudo nano /etc/valkey/instances/6379.conf
    ```

2.  Paste the following configuration. This is a minimal, production-safe starting point.

    ```conf
    # Network
    port 6379
    bind 127.0.0.1 -::1 # Binds to localhost only for security. Change if needed.

    # General
    daemonize no
    supervised systemd
    pidfile /run/valkey/valkey-6379.pid
    loglevel notice
    logfile /var/log/valkey/valkey-server-6379.log

    # Data and Persistence
    dir /var/lib/valkey/6379
    dbfilename dump.rdb

    # Append Only File (AOF) - Recommended for production durability
    appendonly yes
    appendfilename "appendonly.aof"
    ```

#### Instance 2: Port 6380

1.  Create the config file `6380.conf`:

    ```bash
    sudo nano /etc/valkey/instances/6380.conf
    ```

2.  Paste a similar configuration, but change all instance-specific values:

    ```conf
    # Network
    port 6380
    bind 127.0.0.1 -::1

    # General
    daemonize no
    supervised systemd
    pidfile /run/valkey/valkey-6380.pid
    loglevel notice
    logfile /var/log/valkey/valkey-server-6380.log

    # Data and Persistence
    dir /var/lib/valkey/6380
    dbfilename dump.rdb

    # Append Only File (AOF)
    appendonly yes
    appendfilename "appendonly.aof"
    ```

### Step 5: Set Permissions

The `valkey` user (created during package installation) needs to own the directories and files we created.

```bash
# Set ownership for config, data, and log directories
sudo chown -R valkey:valkey /etc/valkey/instances
sudo chown -R valkey:valkey /var/lib/valkey
sudo chown -R valkey:valkey /var/log/valkey

# Set restrictive permissions on the data directory
sudo chmod 750 /var/lib/valkey/*
```

### Step 6: Start and Enable the Services

Now you can manage your Valkey instances individually.

1.  **Reload the systemd daemon** to make it aware of the new `valkey-server@.service` template:

    ```bash
    sudo systemctl daemon-reload
    ```

2.  **Start the instances:**

    ```bash
    sudo systemctl start valkey-server@6379
    sudo systemctl start valkey-server@6380
    ```

3.  **Enable the instances to start on boot:**

    ```bash
    sudo systemctl enable valkey-server@6379
    sudo systemctl enable valkey-server@6380
    ```

### Step 7: Verify the Setup

1.  **Check the status of each service:**

    ```bash
    sudo systemctl status valkey-server@6379
    sudo systemctl status valkey-server@6380
    ```
    You should see that they are `active (running)`.

2.  **Connect to each instance using `valkey-cli`:**

    ```bash
    # Connect to the first instance
    valkey-cli -p 6379 PING
    # Expected output: PONG

    # Connect to the second instance
    valkey-cli -p 6380 PING
    # Expected output: PONG
    ```

3.  **Check the logs:**

    ```bash
    sudo tail -f /var/log/valkey/valkey-server-6379.log
    sudo tail -f /var/log/valkey/valkey-server-6380.log
    ```

### Managing Your Instances

You can now use standard `systemctl` commands with the `@<port>` syntax:

*   **Stop an instance:** `sudo systemctl stop valkey-server@6379`
*   **Restart an instance:** `sudo systemctl restart valkey-server@6380`
*   **Disable an instance from starting on boot:** `sudo systemctl disable valkey-server@6379`

### Adding a New Instance (e.g., Port 6381)

This setup is now easily scalable. To add a third instance:

1.  `sudo mkdir /var/lib/valkey/6381`
2.  `sudo cp /etc/valkey/instances/6379.conf /etc/valkey/instances/6381.conf`
3.  Edit `/etc/valkey/instances/6381.conf` and change all occurrences of `6379` to `6381`.
4.  `sudo chown -R valkey:valkey /var/lib/valkey/6381 /etc/valkey/instances/6381.conf`
5.  `sudo systemctl start valkey-server@6381`
6.  `sudo systemctl enable valkey-server@6381`

You have now successfully configured multiple, isolated, production-ready Valkey instances on a single Ubuntu machine.

## Secure Passwords

Hardcoding passwords directly into the main configuration files (`/etc/valkey/instances/*.conf`) is a security risk, as these files are often readable by more users than necessary and can be accidentally checked into version control.

The best practice is to store the password in a separate, highly-restricted file and then have the main configuration file include it. We will also need to update our `systemd` service file to handle authentication when shutting down the instance.

Here is a secure, step-by-step guide to adding password protection to your multi-instance Valkey setup.

---

### Strategy: Separate Secrets from Configuration

We will use the following approach:

1.  Create a dedicated directory for secrets: `/etc/valkey/secrets`.
2.  For each instance, create a small, separate file inside `/etc/valkey/secrets` that contains only the `requirepass` directive.
3.  Set highly restrictive permissions (`600`) on these secret files so that only the `valkey` user (and `root`) can read them.
4.  Use the `include` directive in our main instance configuration files to load the password.
5.  Update the `systemd` template to use the password for the `ExecStop` command.

---

### Step 1: Generate Strong Passwords

First, generate strong, unique passwords for each instance. Do not reuse passwords. A good way to generate a random string is using `openssl`:

```bash
# Generate a password for instance 6379

openssl rand -base64 32

# Generate a password for instance 6380

openssl rand -base64 32

```
Save these generated passwords in a secure location for the next step. For this example, let's assume:

*   **Instance 6379 password:** `SuperS3cur3Passw0rdFor6379!`
*   **Instance 6380 password:** `An0therV3ryStr0ngPassFor6380!`

### Step 2: Create the Secrets Directory and Files

1.  **Create the dedicated directory for secrets:**

    ```bash
    sudo mkdir /etc/valkey/secrets
    ```

2.  **Create the password file for instance 6379:**

    ```bash
    sudo nano /etc/valkey/secrets/6379.pass.conf
    ```
    Add the following line to the file, using the password you generated:
    
    ```conf
    requirepass SuperS3cur3Passw0rdFor6379!
    ```

3.  **Create the password file for instance 6380:**

    ```bash
    sudo nano /etc/valkey/secrets/6380.pass.conf
    ```
    
    Add the following line to the file:
    
    ```conf
    requirepass An0therV3ryStr0ngPassFor6380!
    ```

### Step 3: Set Strict File Permissions

This is the most critical step for security. We need to ensure that only the `valkey` process (running as the `valkey` user) and the `root` user can access these files.

```bash
# Set ownership of the secrets directory and files to the valkey user
sudo chown -R valkey:valkey /etc/valkey/secrets

# Set permissions:
# 700 on the directory: Only the owner (valkey) can access it.
# 600 on the files: Only the owner (valkey) can read/write them.
sudo chmod 700 /etc/valkey/secrets
sudo chmod 600 /etc/valkey/secrets/*.pass.conf
```

### Step 4: Update the Main Configuration Files

Now, modify your instance configuration files in `/etc/valkey/instances/` to include the new secret files.

1.  **Edit `6379.conf`:**

    ```bash
    sudo nano /etc/valkey/instances/6379.conf
    ```
    
    Add this `include` line at the end of the file:
    
    ```conf
    # Include the password configuration from a secure file
    include /etc/valkey/secrets/6379.pass.conf
    ```

2.  **Edit `6380.conf`:**

    ```bash
    sudo nano /etc/valkey/instances/6380.conf
    ```
    Add this `include` line at the end of the file:
    ```conf
    # Include the password configuration from a secure file
    include /etc/valkey/secrets/6380.pass.conf
    ```

### Step 5: Update the `systemd` Service File

Our `ExecStop` command (`valkey-cli ... shutdown`) will now fail because it can't authenticate. We need to provide the password securely. We can do this by having the command read the password directly from the file.

1.  **Edit the template unit file:**

    ```bash
    sudo nano /etc/systemd/system/valkey-server@.service
    ```

2.  **Modify the `ExecStop` line.** The original line was:

    `ExecStop=/usr/bin/valkey-cli -p %i shutdown`

    Change it to the following. This command uses shell substitution to read the password from the correct file and pass it to `valkey-cli` using the `-a` (authenticate) flag.

    ```ini
    ExecStop=/bin/sh -c 'exec /usr/bin/valkey-cli -p %i -a "$(cat /etc/valkey/secrets/%i.pass.conf | cut -d " " -f 2)" shutdown'
    ```

**Why this `ExecStop` command is secure:**

*   It reads the password directly from the file at the moment of execution.
*   The password is not stored in the `systemd` unit file itself.
*   The password does not appear in the process list (`ps aux`) for other users to see.
*   The `cut` command is used to extract just the password, in case the secret file has extra whitespace or comments.

### Step 6: Reload and Restart

Apply all the changes by reloading `systemd` and restarting your Valkey instances.

1.  **Reload the systemd daemon:**

    ```bash
    sudo systemctl daemon-reload
    ```

2.  **Restart the instances:**

    ```bash
    sudo systemctl restart valkey-server@6379
    sudo systemctl restart valkey-server@6380
    ```

### Step 7: Verify the Password Protection

1.  **Try to connect without a password (this should fail):**

    ```bash
    valkey-cli -p 6379 PING
    # Expected output: (error) NOAUTH Authentication required.
    ```

2.  **Connect using the correct password:**

    ```bash
    # Get the password from your secure note
    valkey-cli -p 6379 -a 'SuperS3cur3Passw0rdFor6379!' PING
    # Expected output: PONG
    ```

3.  **Verify the other instance:**

    ```bash
    valkey-cli -p 6380 -a 'An0therV3ryStr0ngPassFor6380!' PING
    # Expected output: PONG
    ```

4.  **Verify that the service can stop correctly (this tests your `ExecStop` command):**

    ```bash
    sudo systemctl stop valkey-server@6379
    sudo systemctl status valkey-server@6379
    # The service should show as 'inactive (dead)'
    sudo systemctl start valkey-server@6379
    ```

We now have secured the multi-instance Valkey setup with unique, securely-stored passwords for each instance. This approach effectively separates configuration from secrets and is a robust pattern for production environments.

**NOTE**: *this could be enhanced by using dotenvx to encrypt/decrypt the keys*

###### dpw | 2025-07-25
