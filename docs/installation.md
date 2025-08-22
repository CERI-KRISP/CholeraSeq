# Installation Instructions for Nextflow, Docker, and Java JDK 17 LTS on Ubuntu


In this document, we provide instructions (with minimal assumptions of target hardware) required by a user to initiate testing of the pipeline.

If you need to install this pipeline on a cluster (HPC or K8s) then please refer the to the nf-core docs and community.

:::{.callout-tip}
## nf-core documentation
As the CholeraSeq pipeline uses nf-core template, the extensive documentation regarding [installation](https://nf-co.re/docs/usage/getting_started/configuration), configuration and [customization](https://training.nextflow.io/2.1/other/nf_customize/) of the pipeline are applicable for CholeraSeq.
:::



## Prerequisites

- Ubuntu Linux (18.04 or newer recommended)
- `curl` and `wget` installed

---


## 1. Install Java JDK 17 LTS

Nextflow requires Java 17 or later. Here, we install OpenJDK 17 LTS:

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

nextflow run hello
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
