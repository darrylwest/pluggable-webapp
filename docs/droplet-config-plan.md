# Digital Ocean Droplet Config Plan

## Execution Steps

_**Execute this plan by providing the YAML to your DigitalOcean Droplet.**_

1. Navigate to Droplet Creation: In your DigitalOcean control panel, go to "Create" and select "Droplets".
2. Configure Your Droplet: Choose your desired Ubuntu image, datacenter region, and droplet plan.
3. Enter User Data: In the "Authentication" section, select "SSH Keys" if you want to add a root key as a backup, but the crucial step is to scroll down to the "Select additional options" section and check the box for "User data".
4. Paste the YAML: A text box will appear. Paste the entire cloud-config.yaml content (from #cloud-config onwards) into this "User data" text box.
5. Create the Droplet: Finalize any other settings and click the "Create Droplet" button.

Upon its first boot, your new droplet will automatically process this user data with cloud-init, and your dpw user will be ready and configured within a minute or two. You can then log in directly using `ssh dpw@your_droplet_ip`.


```yaml
#cloud-config
# -------------------------------------------------------------------
# Final cloud-config for user 'dpw'
# -------------------------------------------------------------------

# 1. Define custom groups first to ensure they exist before creating users.
groups:
  - dpw

# 2. Define users, their groups, sudo rights, and SSH keys.
users:
  - name: dpw
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: dpw, sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9jB0bMvV6ybd1XSqOKP6ktn8jhwb8agyQ3wX1gCARfgUFlmV9UydE3WGi7Jpj6OmEnclJiLCJhvgKsvYHnm+XPtzGgiTF9KIZSivNWwpsCelhA6/pTv3lOZGwCRSifsbDzsgvDlncecmDoA4AyK6AMzb6s7WrGNBH/AM5mYGqc4lm88wHfYKnw4YzCAxG/9oyR09bMx57iv+anqILYnqwMMG6C00QL2KisIYUnaV+0ghQhxmWZzWRWUygO08n54tzxyahSJe+1HAyYOajMpSp3r0V659Zs3XK5+tEgU7lAy30mxy43u6WnnvQpydSWflJjuYaTgzkrjqxOf+PMlIRoU0aKZvJnP0ApZXoSqbYt/S1xKol/lPMOOmVF2rD5KVwvrb88A0tC1fonNKpc5pU5in9rr43TiPfAU87T3RjvCeILfIaYGWKq+9wMlej1zvRLuMRygDGi+834nFm1RYlvCn+vpbQAeOLzgtRDWKughl9kJC81xk8QjV+0jJdo48= dpw@Mac-mini.localdomain"
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2ogqtgTOqtPOBuJKJYBY1F5opm/HPFwVEp5ifMulv3NkTA/0rv0LeZ1Xti+iiIB9434CYMFfsiXFh3cDamKcjG0OjO0NLAEzgUo35FWq4GxdU5RKOe3y0MGgDl9qvAnRTSr0U3BpMSPANOpZpM0EnJdLzW5LI0D6bEZvkKU7PIrBkA3mumVd9zbC0G+Iihwx1owxepVsr78J04XDMhW516qyxZ3jG8uqpChoy5BBVpqFcNwlm2/yNvekyR438kkvE613aTFrkXZ50dvmAxF01ZGiAnAyEWOLrf9Df9LQfwrGekksoCkdDhXBCAnY7vfEK31KKnVVVtRC/m5KDr1J0UIR9zrMD2eXwOey3uY2dxrp51nsx+xFwyW7TokrZF1d3nN6+xvGUka/EYZMWjzM8eXX+3JWGzxcaT+aQn50VHJlaG4tyBOy6Y48PYkCAfocJZBv71HzNkheWRC6OSq9FNMRannb+0iX2BAND4vuUsKN8rolrUGdYLSmqio45zbc= dpw@BCT-MBP.localdomain"
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDD/bMn9zf9vK1Su44V5FPEipVLvukXKxUqYj/3qbbG0djtlRVYQU3RrfwFDQ0pqQQjelDv0JfiOiKQEmZ7qpin0MCgucAGQmIsz85N28FCTAaQ4o6sJf2hu0Mpn9dGmhKuJk7mc23JnfB9mOC/9+JhJXVtmXKx9TQKdWvARrqQCHAcvIWkpb2WWrMyt+jJOjlT9Ae0Gzz/7V6ITwr4ozNneCeIC5rx9x/Ky8aiGQvAU4RFV8C9wcghnEqLDd1vIqGAU9UbkW5IvKbnAXJlkmp9+d5PMbdvndXrTDaIc/QhkynOovps0yuXTK3wpIULT9ManxqUsqt9xpP3uIWmWbht57pigz3+fLtVCs0NS6VsIYLgnwzwxFjnUakCc+TSTq335+8Db7L0cwdTeOw/9Ctc0yCeKgfGYnd+6+1J6p08ruEiM+4/Bc3esiZ9n7pSX7pyTU6+3DDRVZfT6g2FUZCfZ7QhSoX2no6mM2YC4YrzqoSOOvnYbKgpzXdqoDEdttM= dpw@iMac.localdomain"
```

**NOTE: this did not work, so if it fails, 

## Test Installation

1. Log in for the first time as your new user: `ssh dpw@your_droplet_ip`
2. Confirm that you can run sudo commands, for example, sudo apt update.
3. Once you have confirmed your dpw user works perfectly, you should then harden the server's security by disabling root login over SSH.
    1. while logged in as `dpw` verify that `sudo` works
    2. remain logged in as `dpw` and on another terminal login as `root`
    3. edit `/etc/ssh/sshd_config` to set `PermitRootLogin no`
    4. on a third terminal, attempt to login as `root`
    5. confirm that you **cannot** login as root but you can as `dpw`

## Manual Steps (incase the yaml fails)

Here is a concise recap of the successful manual steps we took to create a secure, sudo-enabled user and harden your server.

### **Final Documentation: Manually Configuring a Sudo User on a New Ubuntu Droplet**

This guide outlines the successful, verified steps to create a new user named `dpw`, grant them administrative privileges, and secure the server by disabling direct `root` login via SSH.

#### **Phase 1: Create the User and Grant Sudo Group Membership**

*These steps were performed while logged in as `root`.*

1.  **Create the User and Primary Group:** The `adduser` command was used to create the user `dpw`, their home directory (`/home/dpw`), and a matching primary group (`dpw`) all in one step.
    ```bash
    adduser dpw
    ```
    (We then followed the interactive prompts to set a password and user information).

2.  **Add User to the `sudo` Group:** To grant administrative privileges, the `dpw` user was added to the `sudo` supplementary group.
    ```bash
    usermod -aG sudo dpw
    ```

#### **Phase 2: Configure SSH Key Authentication**

*This critical phase ensures passwordless login for the new user.*

1.  **Switch to the New User:** To ensure correct file ownership and permissions, we switched to the `dpw` user's session.
    ```bash
    su - dpw
    ```

2.  **Create and Secure the `.ssh` Directory:**
    ```bash
    mkdir ~/.ssh
    chmod 700 ~/.ssh
    ```

3.  **Create and Secure the `authorized_keys` File:**
    ```bash
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    ```

4.  **Add Public Keys:** A text editor (`nano` or `vi`) was used to open the file, and all necessary public SSH keys were pasted into it, each on a new line.
    ```bash
    nano ~/.ssh/authorized_keys
    ```

5.  **Return to `root`:** After saving the keys, we returned to the root session.
    ```bash
    exit
    ```

#### **Phase 3: Configure Passwordless Sudo**

*This step enhances convenience for an administrative user. It was performed as `root`.*

1.  **Safely Edit Sudoers Configuration:** The `visudo` command was used to prevent syntax errors.
    ```bash
    visudo
    ```

2.  **Add User-Specific Rule:** The following line was added to the end of the file, granting `dpw` the ability to run any command with `sudo` without a password prompt.
    ```
    dpw    ALL=(ALL) NOPASSWD:ALL
    ```

#### **Phase 4: Harden Server by Disabling Root SSH Login**

*This is the final security step, performed from the verified `dpw` user's SSH session.*

1.  **Edit the SSH Service Configuration:**
    ```bash
    sudo nano /etc/ssh/sshd_config
    ```

2.  **Set `PermitRootLogin` to `no`:** The `PermitRootLogin` directive was found and changed to ensure it read exactly as follows, with no leading `#`.
    ```
    PermitRootLogin no
    ```

3.  **Restart the SSH Service:** The SSH service was restarted to apply the new configuration, using the correct service name for Ubuntu.
    ```bash
    sudo systemctl restart ssh.service
    ```

4.  **Final Verification:** A new terminal was opened to confirm that `ssh root@your_droplet_ip` **failed** and `ssh dpw@your_droplet_ip` **succeeded**.

---

This process resulted in a production-ready server with a secure, non-root user for all administrative tasks.

## Next Steps

### dpw-env

* `sudo apt update && sudo apt upgrade -y`
* As that's running I will work on my env aliases, etc. from alamo: `scp .bash_aliases dpw@146.190.1.182`
* add `.motd` for aliases
* create keys for git `ssh-keygen -t rsa -f id_rsa -P ''` ; add pub to github & gitlab
* pulled cpp-sandbox and cpp-utils and switched to the develop branch
* **power off**, **snapshot** dpw-env **power on**
 
### c++23 env

This installs g++-14, node 20.16, jq, neovim, etc

```bash
sudo apt update

sudo apt install -y build-essential make binutils autoconf automake libtool libgmp-dev pkg-config \
     libmpfr-dev libmpc-dev flex bison texinfo curl wget uuid-dev python3-dev libstdc++6 locales openssh-client \
     xz-utils git vim neovim ninja-build fswatch openssl libssl-dev iputils-ping jq libsodium-dev libncurses-dev \
     nlohmann-json3-dev procps ca-certificates gnupg software-properties-common \
     gcc-14 g++-14 nodejs npm clang-format-18 lcov
```

### usr/local/bin/ from docker

From `docker-environments/ubuntu-gcc14`

* mkcmd (bash version) just copied
* scp task-runner 
* scp txkey

### rust

```bash
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s -- -y

~/.cargo/bin/cargo --version
```

* logout and back in to verify `cargo` is in the PATH
* `cargo install lsd`
* `cargo install bat`
* cp .config/nvim/init.vim
* `curl -fsSL https://bun.sh/install | bash`

* **power off**, **snapshot** -dev **power on**

###### dpw | 2025.07.18
