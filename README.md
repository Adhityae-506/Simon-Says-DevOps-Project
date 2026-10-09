# Simon Says DevOps Project

A practice DevOps project that packages a browser-based **Simon Says memory game** in Docker, publishes the image to GitHub Container Registry (GHCR) through Jenkins, and provisions AWS infrastructure with Terraform.

## Project Overview

The project demonstrates these stages:

1. Store the application and infrastructure code in GitHub.
2. Use Jenkins to initialize, validate, plan, and apply the Terraform configuration.
3. Provision AWS infrastructure in the Mumbai region (`ap-south-1`).
4. Build the application Docker image and publish it to GHCR.
5. Connect to an EC2 instance, pull the published image, and run the container manually.
6. Open the application in a browser using the EC2 public IP and exposed port.

**Deployment note:** The Terraform infrastructure and GHCR image build/push are handled through Jenkins. The container start/pull step on EC2 is manual in this project; the EC2 user-data script installs Docker and logs in to GHCR but does not itself pull or start the application container.

## Architecture

```text
GitHub repository
├── Simon_Says_Source_Files/
│   ├── index.html, styles.css, script.js, assets/
│   └── Dockerfile
└── Terraform_Files/
    ├── VPC, subnets, Internet Gateway and route table
    ├── Security group
    ├── EC2 instances and user data
    └── Terraform variables and outputs

Jenkins
├── Terraform init / validate / plan / apply
└── Docker build / GHCR login / Docker push

GHCR image
    ↓ manual pull on EC2
Docker container (host port 5000 → container port 80)
    ↓
Nginx serves the Simon Says application
```

## Technologies Used

- **HTML, CSS, JavaScript** — Simon Says frontend
- **Nginx Alpine** — serves the static application files
- **Docker** — packages the frontend into a container image
- **GitHub Container Registry (GHCR)** — stores the published image
- **Jenkins** — runs the Terraform and image build/publish steps
- **Terraform** — defines and provisions AWS infrastructure
- **AWS EC2, VPC, subnets, Internet Gateway, route tables, security groups** — compute and networking

## Repository Structure

```text
Simon-Says-DevOps-Project/
├── Simon_Says_Source_Files/
│   ├── assets/
│   ├── Dockerfile
│   ├── index.html
│   ├── script.js
│   ├── styles.css
│   └── README.md
└── Terraform_Files/
    ├── .gitignore
    ├── .terraform.lock.hcl
    ├── ec2.tf
    ├── outputs.tf
    ├── provider.tf
    ├── route_table.tf
    ├── security_group.tf
    ├── user_data.sh
    ├── variables.tf
    └── vpc.tf
```

## Application

The Simon Says game is a memory game with a hard-mode sequence: each round displays only the newly added color, and the player must recall the full sequence in order. It includes a responsive UI, score/level tracking, animations, and local sound assets.

See the [application README](Simon_Says_Source_Files/README.md) for gameplay details.

## Docker Image

The Dockerfile uses `nginx:alpine` and copies the application directory into Nginx's default web root, `/usr/share/nginx/html`.

From the repository root, build the image with:

```bash
docker build -t simon-says-img ./Simon_Says_Source_Files
```

Tag and push the image to GHCR (the Jenkins job used this package name):

```bash
docker tag simon-says-img ghcr.io/adhityae-506/simon-says-img:latest
docker login ghcr.io -u YOUR_GITHUB_USERNAME
docker push ghcr.io/adhityae-506/simon-says-img:latest
```

When prompted by `docker login`, use a GitHub token with the required package permissions, not your GitHub account password. In Jenkins, store credentials in Jenkins Credentials and bind them as environment variables. Never commit tokens or print them into build logs.

## AWS Infrastructure with Terraform

Terraform configuration is in `Terraform_Files/`. The current configuration defines:

- A VPC with CIDR `11.0.0.0/16`
- Two public subnets (`11.0.1.0/24` and `11.0.2.0/24`) in `ap-south-1a` and `ap-south-1b`
- An Internet Gateway and a route table with a default route to the Internet Gateway
- A security group
- Two `t3.micro` EC2 instances
- User data that installs and enables Docker and logs in to GHCR
- Outputs for both EC2 public IP addresses

The AMI and EC2 key pair are configured in the Terraform files. Before applying, verify that the AMI is valid in `ap-south-1` and that the configured key pair exists in that region.

### Run Terraform locally

From the repository root:

```bash
cd Terraform_Files
terraform init
terraform validate
terraform plan
terraform apply
```

The configuration requires `ghcr_username` and `ghcr_token` variables. Provide them securely via your terminal environment or your CI/CD credential system. For example, a PowerShell session can set `TF_VAR_ghcr_username` and `TF_VAR_ghcr_token` before running Terraform; do not put actual secrets in this README or commit them to Git.

After a successful apply, Terraform prints the public IPs. These may change when instances are replaced; use the current Terraform output or AWS Console values.

### Jenkins

The Jenkins Terraform job uses AWS credentials injected through Jenkins credential bindings, then runs Terraform initialization, validation, planning, and applying. A separate image-publishing step builds the Docker image and pushes it to GHCR.

For non-interactive CI, Terraform apply must be configured to run without an interactive confirmation prompt. Review plans carefully before provisioning or destroying resources.

## Manual EC2 Deployment

After the image is available in GHCR:

1. Open the target EC2 instance in the AWS Console and connect using EC2 Instance Connect.
2. Verify Docker is installed and running.
3. Pull the published image and start the container:

   ```bash
   docker pull ghcr.io/adhityae-506/simon-says-img:latest
   docker run -d --name simon-says-container -p 5000:80 ghcr.io/adhityae-506/simon-says-img:latest
   ```

   If the container already exists, inspect it with `docker ps -a` before creating another container with the same name.

4. Check the container and port mapping:

   ```bash
   docker ps
   docker port simon-says-container
   curl -I http://localhost:5000
   ```

5. Add an inbound TCP rule for port `5000` to the attached EC2 security group, with the source restricted to your public IP for testing.
6. Open this URL in a browser:

   ```text
   http://<EC2-PUBLIC-IP>:5000
   ```

The container maps EC2 host port `5000` to Nginx's port `80`. The currently committed Terraform security-group configuration allows ports 22, 80, and 443; if you use host port 5000, add the corresponding restricted ingress rule in Terraform or the AWS Console. If you add it only in the Console, Terraform configuration and the real security group will differ.

## Security and Cost Notes

- Restrict SSH ingress on port `22` to a trusted IP address with a `/32` CIDR. Avoid exposing SSH to `0.0.0.0/0`.
- Restrict the application port to the users who need access unless the site is intended to be public.
- Use Jenkins Credentials for AWS and GHCR secrets; do not commit credentials to source control.
- Terraform state, saved plans, and EC2 user data can contain sensitive values. The `sensitive` Terraform flag masks some displays; it does not remove a secret from state or metadata. Prefer a short-lived or least-privilege GHCR token and secure Jenkins workspace/state access.
- Keep `.terraform.lock.hcl` under version control; do not commit the `.terraform/` directory, state files, variable files containing secrets, or saved plan files.
- AWS resources can incur charges. Check the AWS billing console and destroy unneeded resources when the project is no longer in use.

## Destroy Resources

From `Terraform_Files/`, use:

```bash
terraform destroy
```

Terraform will ask for confirmation. Review the list before proceeding. Supply the required Terraform variables securely if prompted. This removes resources managed by this Terraform state, but does not delete the image already stored in GHCR.

---

Created as a hands-on learning project to understand infrastructure as code, containerization, image registries, and Jenkins-based DevOps workflows.
