# Java Yearbook – End-to-End DevOps Capstone

## Project Overview

This project demonstrates an end-to-end DevOps workflow for deploying a Java Yearbook application and a portfolio website on AWS.

It combines Infrastructure as Code (IaC), configuration management, containerisation, CI/CD automation and application testing.

The project uses **Jenkins for infrastructure provisioning with Terraform** and **GitHub Actions for automated application deployment**. Both pipelines have been implemented and tested.

## Architecture

### Infrastructure and Application Architecture

- AWS VPC provides the network environment.
- Terraform provisions and manages AWS infrastructure.
- An EC2 instance hosts the application environment.
- Ansible automates application deployment and server configuration.
- Docker Compose manages the containerised application services.
- Nginx serves as the web server and reverse proxy.
- The portfolio website and Java Yearbook application are accessible through Nginx.

### CI/CD Architecture

The project uses two CI/CD workflows with different responsibilities.

**1. Jenkins – Infrastructure Provisioning**

Jenkins automates the Terraform infrastructure workflow:

1. Checks out the project repository.
2. Verifies the required toolchain.
3. Validates Terraform configuration.
4. Initialises the remote S3 Terraform backend.
5. Generates and displays a Terraform execution plan.
6. Requests manual approval before applying changes.
7. Applies the approved infrastructure changes.

Terraform state is stored remotely in Amazon S3, with encryption, versioning and state locking enabled.

**2. GitHub Actions – Application Deployment**

GitHub Actions automates application deployment whenever changes are pushed to the `main` branch.

The workflow:

1. Checks out the latest repository code.
2. Sets up Java 21.
3. Builds the Java application using Maven.
4. Executes the Ansible deployment playbook.
5. Deploys the application to the existing AWS EC2 instance.
6. Runs HTTP smoke tests to verify application availability.

The workflow can also be triggered manually through GitHub Actions using `workflow_dispatch`.

A self-hosted GitHub Actions runner runs on WSL Ubuntu and executes the deployment job.

## Technology Stack

| Category | Technologies |
|---|---|
| Cloud Platform | Amazon Web Services (AWS) |
| Infrastructure as Code | Terraform |
| Configuration Management | Ansible |
| CI/CD – Infrastructure | Jenkins |
| CI/CD – Application | GitHub Actions |
| Runner | GitHub Self-hosted Runner on WSL Ubuntu |
| Application | Java 21, Maven |
| Containerisation | Docker, Docker Compose |
| Web Server / Reverse Proxy | Nginx |
| Version Control | Git, GitHub |
| Infrastructure State | Amazon S3 |

## Project Structure

```text
java-yearbook-project/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── ansible/
│   └── playbook.yml
├── java/
│   └── pom.xml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── output.tf
│   └── ...
├── Jenkinsfile
├── docker-compose.yml
├── README.md
└── ...
```

*The structure above highlights the main project components; supporting application, Docker and Nginx files are also included in the repository.*

## Deployment Workflows

### Jenkins Infrastructure Deployment

The Jenkins pipeline is responsible for provisioning and managing AWS infrastructure.

The infrastructure deployment process includes:

- Terraform formatting and validation.
- Remote backend initialisation.
- Terraform planning.
- Manual approval.
- Terraform apply.

The pipeline uses AWS credentials configured in Jenkins rather than storing access keys in the repository.

The Terraform state is maintained in an encrypted S3 backend with state locking.

### GitHub Actions Application Deployment

The GitHub Actions workflow is defined in:

`.github/workflows/deploy.yml`

The workflow is triggered by:

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:
```

The deployment process is:

```text
Developer pushes code to GitHub
             |
             v
      GitHub Actions
             |
             v
      Checkout Code
             |
             v
       Setup Java 21
             |
             v
       Maven Build
             |
             v
     Ansible Deployment
             |
             v
        AWS EC2
             |
             v
      HTTP Smoke Tests
             |
             v
       Deployment Result
```

The GitHub Actions runner is self-hosted on WSL Ubuntu. It must be running and connected to the internet to receive deployment jobs.

The workflow currently runs the complete application deployment process on each push to `main`. It does not use Git-diff-based selective deployment.

## Testing and Verification

The following workflows have been executed successfully:

| Test / Activity | Platform | Result |
|---|---|---|
| Terraform validation | Jenkins | Successful |
| Terraform remote backend initialisation | Jenkins | Successful |
| Terraform plan and approval | Jenkins | Successful |
| Terraform infrastructure apply | Jenkins | Successful |
| Java 21 setup | GitHub Actions | Successful |
| Maven application build | GitHub Actions | Successful |
| Ansible application deployment | GitHub Actions | Successful |
| HTTP smoke tests | GitHub Actions | Successful |
| GitHub self-hosted runner connection | WSL Ubuntu | Successful |

The HTTP smoke tests verify the application endpoints:

- `/` – Portfolio homepage.
- `/yearbook/` – Java Yearbook application.

## Security Considerations

- AWS credentials are stored in Jenkins credentials management.
- SSH access uses a private deployment key stored outside the Git repository.
- Terraform state is stored in an encrypted S3 backend.
- S3 public access is blocked.
- Terraform state locking helps prevent concurrent state modifications.
- Sensitive Terraform variables and local configuration files are excluded from Git.
- The EC2 SSH security group restricts administrative access to the configured IP range.

## Key DevOps Concepts Demonstrated

This project demonstrates practical experience with:

- AWS infrastructure provisioning.
- Terraform state management and remote backends.
- Infrastructure validation, planning and controlled application.
- Jenkins pipeline automation.
- GitHub Actions workflow automation.
- Self-hosted CI/CD runners.
- Ansible configuration management and deployment.
- Java application build automation with Maven.
- Docker and Docker Compose.
- Nginx reverse proxy configuration.
- Automated HTTP smoke testing.
- Git-based version control and deployment triggers.

## Future Improvements

Potential improvements include:

- Upgrade GitHub Actions dependencies to their current supported versions.
- Introduce path-based deployment to avoid rebuilding and redeploying unaffected application components.
- Add automated application and integration tests.
- Introduce deployment rollback procedures.
- Improve monitoring, logging and alerting.
- Strengthen deployment security and access management.

## Conclusion

This capstone demonstrates two complementary CI/CD approaches.

Jenkins is used to automate AWS infrastructure provisioning through Terraform, including a controlled approval and apply process.

GitHub Actions is used to automate application builds and deployments through a self-hosted runner, Ansible and HTTP smoke tests.

Together, these workflows demonstrate how infrastructure automation and application delivery can be separated into distinct but complementary DevOps processes.
