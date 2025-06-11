# Installation Instructions for Nextflow, Docker, and Java JDK 17 LTS on Ubuntu

## Prerequisites

- Ubuntu Linux (18.04 or newer recommended)
- `curl` and `wget` installed

---


> :heavy_check_mark: **With this you're all set with Nextflow. Next stop, conda or docker - pick one!**: <br>


## 1. Install Java JDK 17 LTS

Nextflow requires Java 8 or later. Here, we install OpenJDK 17 LTS:

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk
```


The `java` version should NOT be an `internal jdk` release! You can check the release via `java --version`
Notice the `LTS` next to `OpenJDK` line.


```bash

$ java -version
openjdk version "17.0.7" 2023-04-18 LTS
OpenJDK Runtime Environment (build 17.0.7+7-LTS)
OpenJDK 64-Bit Server VM (build 17.0.7+7-LTS, mixed mode, sharing)

```


---

## 2. Install Nextflow

```bash
# Download Nextflow
curl -s https://get.nextflow.io | bash

# Move Nextflow to a directory in your PATH
sudo mv nextflow /usr/local/bin/
```

Verify installation:

```bash
nextflow -v
```



- Sanity check for `nextflow` installation

```console
$ nextflow info

  Version: 23.04.1 build 5866
  Created: 15-04-2023 06:51 UTC (08:51 SAST)
  System: Mac OS X 12.6.5
  Runtime: Groovy 3.0.16 on OpenJDK 64-Bit Server VM 17.0.7+7-LTS
  Encoding: UTF-8 (UTF-8)

```


---

## 3. Install Docker

```bash
# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y \
  ca-certificates \
  curl \
  gnupg

# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt update

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

Verify Docker installation:

```bash
sudo docker run hello-world
```

---

## 4. (Optional) Manage Docker as a Non-root User

```bash
sudo usermod -aG docker $USER
# Log out and log back in for group changes to take effect
```

---

You are now ready to use Nextflow with Docker and Java 17 on Ubuntu!
