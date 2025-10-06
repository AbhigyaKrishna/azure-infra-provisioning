# Azure Infrastructure Provisioning

A comprehensive Infrastructure as Code (IaC) solution for deploying scalable, secure Azure infrastructure using Terraform with multi-environment support and automated CI/CD pipelines.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Terraform Modules](#terraform-modules)
- [Environment Configurations](#environment-configurations)
- [CI/CD Pipelines](#cicd-pipelines)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Security](#security)
- [Contributing](#contributing)

## 🎯 Overview

This project provisions a complete Azure cloud infrastructure with the following features:

- **Multi-Environment Support**: Separate configurations for dev, test, and prod environments
- **Network Isolation**: Private and public subnets with NAT Gateway for secure outbound internet access
- **Load Balancing**: Azure Application Gateway with SSL/TLS termination and HTTP to HTTPS redirection
- **Bastion Host**: Secure SSH access to private VMs through a bastion host
- **Infrastructure as Code**: Modular Terraform configurations for maintainability and reusability
- **CI/CD Pipelines**: Automated deployment using both Azure DevOps and Jenkins
- **Application Deployment**: Support for both native Nginx and Docker-based deployments

## 🏗️ Architecture

The infrastructure follows a three-tier architecture pattern:

```
┌─────────────────────────────────────────────────────────────┐
│                     Internet                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴───────────────────────────┐
        │   Public Subnet - 10.x.1.0/24            │
        │   ┌────────────────┐                     │
        │   │ App Gateway    │                     │
        │   │ (SSL/Public IP)│                     │
        │   └────────────────┘                     │
        │                                          │
        │   ┌────────────────┐                     │
        │   │ Bastion Host   │                     │
        │   │ (Public IP)    │                     │
        │   └────────────────┘                     │
        └──────────────────┬───────────────────────┘
                           │
        ┌──────────────────┴───────────────────────┐
        │   Private Subnet - 10.x.2.0/24           │
        │   ┌────────┐ ┌────────┐                  │
        │   │  VM 1  │ │  VM 2  │                  │
        │   │(Nginx) │ │(Nginx) │                  │
        │   └────────┘ └────────┘                  │
        │                                          │
        │   (NAT Gateway for outbound access)      │
        └──────────────────────────────────────────┘
```

### Key Components:

1. **Virtual Network (VNet)**: Isolated network space with custom CIDR blocks
2. **Subnets**:
   - **Public Subnet**: Hosts Application Gateway and Bastion Host
   - **Private Subnet**: Hosts application VMs (no direct internet access)
3. **Application Gateway**: Layer 7 load balancer with SSL/TLS support
4. **NAT Gateway**: Provides outbound internet access for private VMs
5. **Network Security Groups (NSG)**: Firewall rules for traffic control
6. **Virtual Machines**: Ubuntu 24.04 LTS instances running Nginx
7. **Bastion Host**: Jump server in public subnet for SSH access to private VMs

## 📁 Project Structure

```
azure-infra-provisioning/
├── app/                          # Application files
│   ├── docker-compose.yml        # Docker Compose configuration
│   ├── Dockerfile                # Docker image definition
│   ├── generate-ssl.sh           # SSL certificate generation script
│   ├── index.html                # Web application content
│   └── nginx.conf                # Nginx configuration
│
├── environments/                 # Environment-specific configurations
│   ├── dev/                      # Development environment
│   ├── test/                     # Testing environment
│   └── prod/                     # Production environment
│       ├── backend.tf            # Terraform backend configuration
│       ├── locals.tf             # Local variables
│       ├── main.tf               # Main infrastructure configuration
│       ├── output.tf             # Output values
│       ├── provider.tf           # Azure provider configuration
│       ├── terraform.tfvars      # Variable values
│       └── variables.tf          # Variable definitions
│
├── modules/                      # Reusable Terraform modules
│   ├── bastion/                  # Bastion host module
│   ├── compute/                  # VM instances module
│   ├── gateway/                  # Application Gateway module
│   └── network/                  # VNet and subnet module
│
├── jenkins/                      # Jenkins pipeline definitions
│   ├── Jenkinsfile               # Main infrastructure pipeline
│   ├── Jenkinsfile.deploy        # Application deployment pipeline
│   └── Jenkinsfile.deploy-docker # Docker deployment pipeline
│
└── pipeline/                     # Azure DevOps pipeline definitions
    ├── deploy-docker.yml         # Docker deployment pipeline
    ├── deploy.yml                # Application deployment pipeline
    ├── main.yml                  # Main infrastructure pipeline
    └── templates/                # Reusable pipeline templates
        ├── deploy-via-ssh.yml    # SSH deployment template
        └── setup-tf.yml          # Terraform setup template
```

## 🔧 Terraform Modules

### 1. Network Module (`modules/network`)

Creates the foundational networking infrastructure.

**Resources Created:**

- Azure Virtual Network (VNet)
- Two subnets: public and private
- Network Security Groups (NSG) with security rules:
  - SSH access from public subnet (bastion) to private VMs
  - HTTP/HTTPS from Application Gateway to VMs
  - Deny direct SSH from internet
- NAT Gateway with public IP for outbound internet access
- Subnet associations with NSGs and NAT Gateway

**Key Features:**

- Configurable CIDR blocks per subnet
- Security rules for defense in depth
- Bastion host deployed in public subnet alongside Application Gateway

**Inputs:**
| Variable | Description | Type | Required |
|----------|-------------|------|----------|
| `project_name` | Project name for resource naming | string | Yes |
| `environment` | Environment (dev/test/prod) | string | Yes |
| `location` | Azure region | string | Yes |
| `resource_group_name` | Resource group name | string | Yes |
| `address_space` | VNet address space | list(string) | Yes |
| `private_subnet_cidr` | Private subnet CIDR | string | Yes |
| `public_subnet_cidr` | Public subnet CIDR | string | Yes |
| `common_tags` | Common resource tags | map(string) | No |

**Outputs:**

- `vnet_id`: Virtual Network ID
- `private_subnet_id`: Private subnet ID
- `public_subnet_id`: Public subnet ID (for both App Gateway and Bastion)
- `nat_gateway_id`: NAT Gateway ID

### 2. Compute Module (`modules/compute`)

Provisions Linux virtual machines in the private subnet.

**Resources Created:**

- Network Interfaces (one per VM)
- Linux Virtual Machines (Ubuntu 24.04 LTS)
- SSH key authentication configuration

**Key Features:**

- Configurable VM count and size
- Dynamic private IP allocation
- No public IP addresses (private VMs)
- SSH key-based authentication

**Inputs:**
| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `vm_count` | Number of VMs to create | number | 1 |
| `vm_size` | Azure VM size | string | Standard_Av2 |
| `admin_username` | Admin username | string | - |
| `ssh_public_key` | SSH public key | string | - |
| `subnet_id` | Subnet ID for VMs | string | - |

**Outputs:**

- `vm_ids`: List of VM resource IDs
- `vm_private_ips`: List of VM private IP addresses
- `network_interface_ids`: List of network interface IDs

### 3. Gateway Module (`modules/gateway`)

Creates Azure Application Gateway with SSL/TLS support.

**Resources Created:**

- Public IP for Application Gateway
- Azure Key Vault for certificate storage
- Self-signed SSL certificate (auto-generated)
- Application Gateway v2 with:
  - HTTP and HTTPS listeners
  - Backend pools pointing to VMs
  - Health probes for both HTTP and HTTPS
  - SSL termination
  - HTTP to HTTPS redirect

**Key Features:**

- Automatic SSL certificate generation using OpenSSL
- Layer 7 load balancing
- Health monitoring with custom probes
- Auto-scaling capabilities (Standard_v2 tier)

**Inputs:**
| Variable | Description | Type |
|----------|-------------|------|
| `subnet_id` | Subnet ID for Application Gateway | string |
| `backend_ips` | List of backend VM IPs | list(string) |

**Outputs:**

- `application_gateway_id`: Application Gateway ID
- `public_ip_address`: Public IP address
- `backend_pool_id`: Backend pool ID

### 4. Bastion Module (`modules/bastion`)

Deploys a bastion host in the public subnet for secure SSH access.

**Resources Created:**

- Public IP for bastion host
- Network Interface
- Network Security Group allowing SSH from specified CIDR
- Linux Virtual Machine (Ubuntu 24.04 LTS)

**Key Features:**

- Deployed in public subnet alongside Application Gateway
- Configurable SSH source CIDR
- Dedicated NSG with minimal permissions
- SSH key authentication
- Cost-effective VM size (Standard_B1s default)

**Inputs:**
| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `vm_size` | VM size for bastion | string | Standard_B1s |
| `admin_username` | Admin username | string | - |
| `ssh_public_key` | SSH public key | string | - |
| `subnet_id` | Bastion subnet ID | string | - |
| `allowed_ssh_cidr` | Allowed SSH source CIDR | string | "\*" |

**Outputs:**

- `bastion_public_ip`: Bastion host public IP
- `bastion_vm_id`: Bastion VM resource ID

## 🌍 Environment Configurations

The project supports three environments with separate configurations:

### Directory Structure (per environment)

Each environment folder (`dev`, `test`, `prod`) contains:

1. **`backend.tf`**: Terraform state backend configuration

   - Uses Azure Storage Account for remote state
   - Enables state locking and versioning
   - Separate state files per environment

2. **`provider.tf`**: Azure provider configuration

   - Configures Azure RM provider
   - Sets required provider versions

3. **`locals.tf`**: Local variables specific to environment

   - Environment name
   - Merged common tags
   - Admin username
   - VM count and size
   - SSH key path

4. **`variables.tf`**: Input variable definitions

   - Project name
   - Azure location
   - Network CIDR blocks
   - SSH key file path
   - Tags

5. **`terraform.tfvars`**: Actual variable values

   - Environment-specific values
   - Network configurations
   - Tag values

6. **`main.tf`**: Main configuration orchestrating modules

   - Resource group creation
   - Module instantiation (network, compute, gateway, bastion)
   - Inter-module dependencies

7. **`output.tf`**: Output values
   - Bastion public IP
   - VM private IPs
   - Application Gateway public IP
   - Resource IDs

### Environment-Specific Configurations

**Development (`dev`)**

- Location: Central India
- VNet CIDR: `10.0.0.0/16`
- Public Subnet: `10.0.1.0/24` (App Gateway + Bastion)
- Private Subnet: `10.0.2.0/24` (Application VMs)
- VM Count: 1
- VM Size: `Standard_B2s` (cost-effective)
- Purpose: Development and testing

**Test (`test`)**

- Location: Central India
- VNet CIDR: `10.2.0.0/16`
- Public Subnet: `10.2.1.0/24` (App Gateway + Bastion)
- Private Subnet: `10.2.2.0/24` (Application VMs)
- VM Count: 1
- VM Size: `Standard_Av2`
- Purpose: QA and integration testing

**Production (`prod`)**

- Location: Central India
- VNet CIDR: `10.1.0.0/16`
- Public Subnet: `10.1.1.0/24` (App Gateway + Bastion)
- Private Subnet: `10.1.2.0/24` (Application VMs)
- VM Count: 2+ (scalable)
- VM Size: `Standard_D2s_v3` (production-grade)
- Purpose: Production workloads

### Terraform Backend Configuration

State is stored in Azure Storage:

```hcl
resource_group_name  = "tfstate-rg"
storage_account_name = "tfstate202510"
container_name       = "tfstate"
key                  = "<environment>.terraform.tfstate"
```

## 🚀 CI/CD Pipelines

The project includes both Azure DevOps and Jenkins pipeline implementations.

### Azure DevOps Pipelines

Located in the `pipeline/` directory.

#### 1. Main Infrastructure Pipeline (`pipeline/main.yml`)

**Triggers:**

- Push to `main` branch
- Excludes: `.vscode/*`, `.gitignore`, `README.md`

**Parameters:**

- `environment`: Target environment (dev/test/prod)
- `action`: Terraform action (plan/apply/destroy)
- `dockerDeploy`: Deploy with Docker (true/false)

**Stages:**

1. **Validate Stage**

   - Installs Terraform
   - Runs `terraform validate`

2. **Plan Stage**

   - Runs `terraform plan`
   - Publishes plan artifact

3. **Apply Stage** (conditional)

   - Downloads plan artifact
   - Runs `terraform apply`
   - Publishes outputs artifact
   - Triggers deployment pipeline

4. **Destroy Stage** (conditional)

   - Requires separate approval environment
   - Runs `terraform destroy`

5. **Deploy Stages** (conditional)
   - Triggers either Docker or native deployment

**Configuration:**

- Pool: `ubuntu-latest`
- Terraform Version: `1.7.5`
- Service Connection: `Azure-ServiceConnection`

#### 2. Application Deployment Pipeline (`pipeline/deploy.yml`)

**Process:**

1. **Build Stage**:

   - Archives application files (HTML, Nginx config, SSL script)
   - Publishes artifact

2. **Deploy Stage**:
   - Uses SSH deployment template
   - Installs Nginx on VMs
   - Copies application files
   - Generates SSL certificates
   - Configures and starts Nginx

**Deployment Script:**

- Installs Nginx if not present
- Deploys HTML content to `/var/www/html`
- Generates self-signed SSL certificates
- Configures Nginx with SSL
- Verifies deployment

#### 3. Docker Deployment Pipeline (`pipeline/deploy-docker.yml`)

**Process:**

1. **Build Stage**:

   - Builds Docker image
   - Saves image as tar file
   - Publishes artifact

2. **Deploy Stage**:
   - Uses SSH deployment template
   - Installs Docker and Docker Compose
   - Loads Docker image
   - Deploys using Docker Compose

**Deployment Script:**

- Installs Docker runtime
- Installs Docker Compose
- Loads pre-built Docker image
- Runs `docker-compose up -d`
- Verifies container health

#### 4. Deployment Template (`pipeline/templates/deploy-via-ssh.yml`)

Reusable template for SSH-based deployments through bastion host.

**Features:**

- Retrieves bastion and VM IPs from Terraform outputs
- Establishes SSH connection through bastion
- Transfers artifacts to VMs
- Executes deployment scripts on each VM
- Parallel deployment to multiple VMs

**Parameters:**

- `environment`: Target environment
- `adminUsername`: SSH username
- `artifactsToTransfer`: List of artifacts to copy
- `deploymentScript`: Inline deployment script

### Jenkins Pipelines

Located in the `jenkins/` directory.

#### 1. Main Infrastructure Pipeline (`jenkins/Jenkinsfile`)

**Parameters:**

- `ENVIRONMENT`: dev/test/prod
- `ACTION`: plan/apply/destroy
- `DOCKER_DEPLOY`: true/false

**Stages:**

1. **Checkout**: Clone repository

2. **Install Terraform**: Downloads and installs Terraform 1.7.5

3. **Terraform Init**: Initialize with backend configuration

4. **Terraform Validate**: Validate configuration syntax

5. **Terraform Plan**: Create execution plan

6. **Terraform Apply** (conditional):

   - Manual approval gate
   - Applies infrastructure changes
   - Saves outputs
   - Extracts IPs for deployment

7. **Terraform Destroy** (conditional):

   - Manual approval gate
   - Destroys infrastructure

8. **Deploy Application** (conditional):
   - Triggers either `deploy-docker` or `deploy-app` job
   - Passes bastion IP and VM IPs

**Environment Variables:**

```groovy
ARM_CLIENT_ID       = credentials('azure-client-id')
ARM_CLIENT_SECRET   = credentials('azure-client-secret')
ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
ARM_TENANT_ID       = credentials('azure-tenant-id')
```

**Options:**

- Build retention: 30 builds
- Timeout: 1 hour
- No concurrent builds

#### 2. Application Deployment Pipeline (`jenkins/Jenkinsfile.deploy`)

**Parameters:**

- `ENVIRONMENT`: Target environment
- `BASTION_IP`: Bastion host IP
- `VM_IPS`: Space-separated VM IPs

**Deployment Process:**

1. **Validate Parameters**: Ensures IPs are provided

2. **Build Application Package**:

   - Creates tar.gz with app files
   - Archives artifact

3. **Deploy to VMs**:
   - Sets up SSH keys
   - Copies package to bastion
   - Transfers to each VM via bastion
   - Executes deployment script:
     ```bash
     - Install Nginx
     - Stop Nginx
     - Extract application files
     - Copy HTML content
     - Generate SSL certificates
     - Configure Nginx
     - Start and verify Nginx
     ```

**SSH Agent:**
Uses Jenkins credential `azure-ssh-key` for authentication

#### 3. Docker Deployment Pipeline (`jenkins/Jenkinsfile.deploy-docker`)

**Parameters:** Same as application deployment

**Deployment Process:**

1. **Build Docker Image**:

   - Builds image from Dockerfile
   - Tags with build number and latest
   - Saves as tar archive

2. **Package App Files**: Creates tar.gz with Docker Compose files

3. **Deploy to VMs**:
   - Copies Docker image and files to bastion
   - Transfers to VMs
   - Executes deployment script:
     ```bash
     - Install Docker and Docker Compose
     - Load Docker image
     - Run docker-compose up -d
     - Verify containers
     ```

**Post Actions:**

- Cleanup: Docker system prune
- Workspace cleanup

### Pipeline Comparison

| Feature         | Azure DevOps        | Jenkins             |
| --------------- | ------------------- | ------------------- |
| **Trigger**     | Push to main        | Poll SCM (5 min)    |
| **Approval**    | Environment gates   | Input steps         |
| **Artifacts**   | Pipeline artifacts  | Archived artifacts  |
| **Templates**   | YAML templates      | Shared libraries    |
| **Credentials** | Service connections | Jenkins credentials |
| **Agent**       | Microsoft-hosted    | Self-hosted         |

## 📦 Prerequisites

### Required Tools

- **Terraform** >= 1.7.5
- **Azure CLI** >= 2.50.0
- **SSH Key Pair** (for VM access)
- **Git** for version control

### Azure Requirements

1. **Azure Subscription** with appropriate permissions
2. **Service Principal** with Contributor role:

   ```bash
   az ad sp create-for-rbac --name "terraform-sp" --role Contributor \
     --scopes /subscriptions/<subscription-id>
   ```

3. **Storage Account** for Terraform state:
   ```bash
   az group create --name tfstate-rg --location centralindia
   az storage account create --name tfstate202510 --resource-group tfstate-rg \
     --location centralindia --sku Standard_LRS
   az storage container create --name tfstate --account-name tfstate202510
   ```

### CI/CD Requirements

**For Azure DevOps:**

- Azure DevOps organization and project
- Service connection to Azure subscription
- Variable groups for credentials

**For Jenkins:**

- Jenkins server with:
  - Azure CLI plugin
  - SSH Agent plugin
  - Git plugin
- Credentials configured:
  - `azure-client-id`
  - `azure-client-secret`
  - `azure-subscription-id`
  - `azure-tenant-id`
  - `azure-ssh-key` (private key)

## 🚦 Getting Started

### 1. Clone Repository

```bash
git clone https://github.com/AbhigyaKrishna/azure-infra-provisioning.git
cd azure-infra-provisioning
```

### 2. Generate SSH Key

```bash
ssh-keygen -t rsa -b 4096 -f key.pem -N ""
```

This creates `key.pem` (private) and `key.pem.pub` (public).

### 3. Configure Environment

Edit `environments/<env>/terraform.tfvars`:

```hcl
project_name = "your-project-name"
location     = "Central India"

address_space       = ["10.0.0.0/16"]
public_subnet_cidr  = "10.0.1.0/24"   # For App Gateway and Bastion
private_subnet_cidr = "10.0.2.0/24"   # For application VMs

ssh_key_file_path = "../../key.pem.pub"
allowed_ssh_cidr  = "YOUR_IP/32"  # Your public IP for SSH access

common_tags = {
  "ManagedBy" = "Terraform"
  "Owner"     = "YourName"
}
```

### 4. Configure Azure Credentials

**Option A: Environment Variables**

```bash
export ARM_CLIENT_ID="<service-principal-id>"
export ARM_CLIENT_SECRET="<service-principal-secret>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
```

**Option B: Azure CLI Login**

```bash
az login
az account set --subscription "<subscription-id>"
```

### 5. Initialize Terraform

```bash
cd environments/dev  # or test/prod
terraform init
```

### 6. Plan Infrastructure

```bash
terraform plan
```

### 7. Apply Infrastructure

```bash
terraform apply
```

Review the plan and type `yes` to confirm.

### 8. Access Infrastructure

After deployment:

1. **Get Bastion IP**:

   ```bash
   terraform output bastion_public_ip
   ```

2. **SSH to Bastion**:

   ```bash
   ssh -i ../../key.pem azureuser@<bastion-ip>
   ```

3. **SSH to Private VM** (from bastion):

   ```bash
   ssh azureuser@<vm-private-ip>
   ```

4. **Access Application**:
   ```bash
   terraform output gateway_public_ip
   # Open https://<gateway-ip> in browser
   ```

## 💻 Usage

### Manual Deployment

#### Deploy Infrastructure

```bash
cd environments/<env>
terraform init
terraform plan
terraform apply
```

#### Deploy Application (Native Nginx)

```bash
# From bastion host
scp -r app/* azureuser@<vm-private-ip>:/tmp/
ssh azureuser@<vm-private-ip>

# On VM
cd /tmp
chmod +x generate-ssl.sh
./generate-ssl.sh /etc/ssl
sudo cp index.html /var/www/html/
sudo cp nginx.conf /etc/nginx/nginx.conf
sudo systemctl restart nginx
```

#### Deploy Application (Docker)

```bash
cd app
docker build -t nginx-app .
docker save nginx-app -o nginx-app.tar

# Transfer and load on VM
docker load -i nginx-app.tar
docker-compose up -d
```

### CI/CD Deployment

#### Azure DevOps

1. **Trigger Pipeline**:

   - Push to main branch, or
   - Manually trigger from Azure DevOps UI

2. **Select Parameters**:

   - Environment: dev/test/prod
   - Action: plan/apply/destroy
   - Docker Deploy: true/false

3. **Approve Deployment** (for apply/destroy)

#### Jenkins

1. **Trigger Main Pipeline**:

   - Navigate to Jenkins dashboard
   - Select "azure-infrastructure-pipeline"
   - Click "Build with Parameters"

2. **Configure Build**:

   - ENVIRONMENT: dev/test/prod
   - ACTION: plan/apply/destroy
   - DOCKER_DEPLOY: checked/unchecked

3. **Approve Apply/Destroy** when prompted

### Destroy Infrastructure

```bash
cd environments/<env>
terraform destroy
```

Or via CI/CD with `action=destroy` parameter.

## 🔒 Security

### Network Security

1. **Private VMs**: No public IPs, accessible only via bastion
2. **NSG Rules**: Restrictive firewall rules
3. **SSH Access**: Key-based authentication only
4. **Bastion Host**: Single point of entry with configurable source IP
5. **HTTPS**: SSL/TLS encryption for all web traffic

### Secrets Management

1. **Terraform State**: Encrypted in Azure Storage
2. **SSH Keys**: Never committed to repository (.gitignore)
3. **Azure Credentials**: Stored in CI/CD secrets/credentials
4. **SSL Certificates**: Auto-generated, stored in Key Vault

### Best Practices

- Use separate service principals per environment
- Implement least privilege access
- Enable Azure Security Center
- Regular security audits
- Keep Terraform and provider versions updated
- Use locked storage account for state files

### Security Checklist

- [ ] SSH keys are not committed to Git
- [ ] `allowed_ssh_cidr` is set to your IP, not `*`
- [ ] Service principal has minimal required permissions
- [ ] Storage account has access restrictions enabled
- [ ] NSG rules are reviewed and minimized
- [ ] SSL certificates are properly configured
- [ ] All secrets are stored in CI/CD credentials

## 🎛️ Configuration Options

### VM Scaling

Adjust in `environments/<env>/locals.tf`:

```hcl
vm_count = 3  # Number of VMs
vm_size  = "Standard_D2s_v3"  # VM size
```

### Network CIDR

Modify in `terraform.tfvars`:

```hcl
address_space       = ["10.0.0.0/16"]
public_subnet_cidr  = "10.0.1.0/24"   # App Gateway + Bastion
private_subnet_cidr = "10.0.2.0/24"   # Application VMs
```

### Application Gateway

Configure in `modules/gateway/main.tf`:

- Capacity (2-125 instances)
- SKU tier (Standard_v2, WAF_v2)
- SSL policies
- Backend settings

## 📊 Outputs

After successful deployment, Terraform provides:

| Output                | Description                      |
| --------------------- | -------------------------------- |
| `bastion_public_ip`   | Public IP of bastion host        |
| `vm_private_ips`      | Private IPs of application VMs   |
| `gateway_public_ip`   | Public IP of Application Gateway |
| `resource_group_name` | Name of resource group           |
| `vnet_id`             | Virtual Network ID               |

View outputs:

```bash
terraform output
terraform output -json > outputs.json
```

## 🧪 Testing

### Infrastructure Testing

```bash
# Validate Terraform syntax
terraform validate

# Check formatting
terraform fmt -check

# Security scanning
tfsec .

# Cost estimation
terraform plan | grep "Plan:"
```

### Application Testing

```bash
# HTTP redirect to HTTPS
curl -I http://<gateway-ip>

# HTTPS response
curl -k https://<gateway-ip>

# Health check
curl -k https://<gateway-ip>/health
```

## 🐛 Troubleshooting

### Common Issues

**Issue: Terraform init fails**

```
Solution: Check backend storage account exists and you have access
az storage account show --name tfstate202510 --resource-group tfstate-rg
```

**Issue: SSH to bastion fails**

```
Solution: Verify security group allows your IP
Check allowed_ssh_cidr in terraform.tfvars
```

**Issue: Application Gateway unhealthy**

```
Solution: Check backend health probes
- Verify VMs are running Nginx
- Check /health endpoint exists
- Review NSG rules allow traffic from public subnet
```

**Issue: Can't access VMs from bastion**

```
Solution: Ensure SSH key is copied to bastion
ssh-add key.pem
ssh -A azureuser@<bastion-ip>
```

### Debug Mode

Enable Terraform debug logging:

```bash
export TF_LOG=DEBUG
terraform apply
```

## 📝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Make your changes
4. Run tests and validation
5. Commit changes (`git commit -am 'Add new feature'`)
6. Push to branch (`git push origin feature/new-feature`)
7. Create Pull Request

### Code Standards

- Follow Terraform best practices
- Use meaningful variable names
- Add comments for complex logic
- Update documentation
- Test in dev environment first

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👤 Author

**Abhigya Krishna**

- GitHub: [@AbhigyaKrishna](https://github.com/AbhigyaKrishna)

## 🙏 Acknowledgments

- HashiCorp Terraform documentation
- Microsoft Azure documentation
- Open source community

## 📞 Support

For issues and questions:

- Open an issue on GitHub
- Check existing documentation
- Review Terraform/Azure docs

---

**Built with ❤️ using Terraform and Azure**
