# Java Yearbook DevOps Capstone

An end-to-end DevOps project that deploys a Java application and a portfolio website on AWS using Infrastructure as Code, configuration management, containers, reverse proxying, and Jenkins CI/CD.

## Project Overview

This project demonstrates a deployment workflow for two application components:

- **Java Yearbook application** — built with Maven and packaged into a Docker image.
- **Portfolio website** — static HTML, CSS, and supporting assets served by Nginx.

Terraform provisions the infrastructure, Ansible configures the EC2 host and deploys the services, Docker Compose manages the containers, and Jenkins orchestrates the build, deployment, and HTTP smoke tests.

## Architecture

```text
Developer
   |
   v
GitHub Repository
   |
   v
Jenkins CI/CD Pipeline
   |
   +--> Checkout source
   |
   +--> Verify build tools
   |
   +--> Build Java application with Maven
   |
   +--> Connect to EC2 using SSH credentials
   |
   +--> Run Ansible deployment playbook
                |
                v
          AWS EC2 Instance
                |
                v
           Docker Compose
             /        \
            v          v
       Nginx          Java App
       Portfolio      Container
            |
            v
      Public HTTP traffic
            |
            +--> /            Portfolio website
            +--> /yearbook/   Java application via Nginx
```

Terraform is used to provision the infrastructure separately from the application deployment pipeline.

## Technology Stack

| Area | Technologies |
|---|---|
| Cloud infrastructure | AWS EC2, VPC, subnet, internet gateway, route table, security groups |
| Infrastructure as Code | Terraform |
| Configuration management | Ansible |
| CI/CD | Jenkins |
| Java build | Java 21, Maven |
| Containers | Docker, Docker Compose |
| Web server and reverse proxy | Nginx |
| Version control | Git, GitHub |
| Validation | Ansible syntax checks, Jenkins pipeline validation, HTTP smoke tests |

## Repository Structure

```text
java-yearbook-capstone/
├── terraform/
│   └── Infrastructure provisioning files
├── ansible/
│   └── playbook.yml
├── java/
│   ├── Dockerfile
│   └── Maven application source and configuration
├── myportfolio/
│   └── Static website and avatar assets
├── docker-compose.yml
├── docker-compose.prod.yml
├── nginx.conf
├── Jenkinsfile
└── README.md
```

The exact contents of each directory may evolve as the project develops.

## Deployment Modes

The Jenkins pipeline accepts a `DEPLOYMENT_MODE` parameter to select the deployment scope.

| Mode | Intended behaviour |
|---|---|
| `JAVA` | Copies the Java application and deploys the Java service. |
| `PORTFOLIO` | Copies the portfolio files and relevant Nginx/Compose configuration, then deploys the portfolio service. |
| `FULL` | Deploys both the Java and portfolio services. |

Selective deployment reduces unnecessary work by targeting the component being updated. The live behaviour of each mode should be verified independently, particularly when Compose configuration changes.

## CI/CD Pipeline

The Jenkins pipeline contains these stages:

1. **Checkout SCM** — retrieves the repository from source control.
2. **Checkout** — prepares the source workspace.
3. **Verify Toolchain** — checks the required build tools.
4. **Build Java Application** — builds the Java application with Maven.
5. **Deploy to EC2** — uses SSH credentials and Ansible to execute the deployment playbook.
6. **HTTP Smoke Tests** — checks the relevant HTTP endpoints after deployment.

The pipeline uses a Jenkins-managed SSH credential rather than embedding the private key in the repository.

## Application Endpoints

The deployment exposes the portfolio and routes Java application traffic through Nginx.

| Endpoint | Purpose |
|---|---|
| `/` | Portfolio homepage |
| `/avatars/avatar.png` | Portfolio avatar asset |
| `/yearbook/` | Java application through the Nginx reverse proxy |

The EC2 host uses port 80 for public HTTP traffic. The portfolio container also has a host mapping on port 8083 in the current Compose configuration.

SSH is used for administration and deployment. Access should be restricted to trusted source addresses wherever practical.

## Validation and Test Results

The project has been validated through infrastructure and application checks.

- Terraform configuration was previously validated and formatted.
- Ansible playbook syntax checks passed.
- Jenkins successfully validated the Declarative Pipeline syntax.
- Jenkins build **#15** completed successfully.
- The Java Maven build stage passed.
- The Ansible deployment stage passed.
- HTTP smoke tests passed for:
  - `http://98.89.67.243/`
  - `http://98.89.67.243/yearbook/`
  - `http://98.89.67.243/avatars/avatar.png`

These results confirm that the listed checks passed during that build. They do not, by themselves, establish high availability, disaster recovery, or production-grade security.

## Security Considerations

- Keep AWS credentials, private SSH keys, Terraform state, and secret variable files out of version control.
- Use Jenkins credentials for deployment authentication.
- Keep SSH access restricted to trusted addresses where possible.
- Avoid exposing application ports publicly when access through Nginx is sufficient.
- Use least-privilege IAM permissions for infrastructure provisioning.
- Treat Docker daemon access as privileged; use controlled privilege escalation rather than weakening Docker socket permissions.
- Review security group ingress and egress rules before deployment.

## How to Run

### Prerequisites

- AWS account and appropriately scoped AWS credentials
- Terraform
- Ansible
- Jenkins with the required plugins and credentials configured
- Docker and Docker Compose on the target EC2 host
- Java 21 and Maven for building the application
- Git

### Provision infrastructure

Review the Terraform variables and AWS resource configuration, then run Terraform from the appropriate infrastructure directory:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Review the plan before applying it. Apply only when the proposed infrastructure changes are understood and approved.

### Validate Ansible

From the repository root:

```bash
ansible-playbook -i terraform/inventory.ini \
  ansible/playbook.yml --syntax-check
```

The inventory path must exist and match the current infrastructure configuration.

### Deploy with Jenkins

1. Configure the repository in Jenkins.
2. Configure the required SSH credential using the ID expected by the Jenkinsfile.
3. Confirm that the EC2 host is reachable and its host key is verified.
4. Run the pipeline using the desired `DEPLOYMENT_MODE`.
5. Review the deployment logs and HTTP smoke-test results.

## Limitations and Future Improvements

Potential next improvements include:

- Verify all three deployment modes independently.
- Test rollback procedures and failed deployment recovery.
- Improve deployment idempotency and avoid unnecessary host setup on every run.
- Add application health checks and stronger post-deployment verification.
- Review IAM permissions, network access, secret handling, and container image management.
- Add automated linting and security scanning to the pipeline.

## Project Status

The Jenkins pipeline has successfully built and deployed the Java application and passed its configured HTTP smoke tests. Selective deployment modes are implemented in the current pipeline and Ansible playbook; each mode should be tested independently before the workflow is considered fully verified.

