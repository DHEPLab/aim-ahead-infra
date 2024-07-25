# AugMed-infra

## Install hook locally

### 1. Install with brew

```bash
brew install pre-commit tflint tfsec trivy checkov detect-secrets
```

### 2. Install the git hook scripts

Go to root direcotry of project

```bash
pre-commit install
```

- now pre-commit will run automatically on git commit!

### 3. (Optional) Run against all the files

It's usually a good idea to run the hooks against all the files when adding new hooks (usually pre-commit will only run on the changed files during git hooks)

```bash
pre-commit run -a
```

## Provision infrastructure
### Introduction
This project is about to deploy below services on AWS via terraform:
* A backend server on ECS
* A frontend server on ECS
* A RDS database and its replica
* AN ALB to publish api and web app

The environment folder is the main module for different env where maintain the corresponding variables.

### Provision from local
1. Config your own AWS account
   ```bash
   export AWS_ACCESS_KEY_ID={your_access_key}
   export AWS_SECRET_ACCESS_KEY={your_secret_key}
   ```
2. Go into the `env` folder(ie: src/environments/dev)
3. Run terraform commands
   ```bash
   terraform init
   terraform validate
   terraform plan
   terraform apply
   ```
### Provision automatically
A Github workflow will be triggered after push codes to master branch, and its step:
1. Check secrets
2. Code scan, including: lint, vulnerability scan
3. Terraform format&validate
4. Apply to aws (Only if head commit message contains `[!go deploy!]`)

> Please notice:
> 1. The AWS account is configured in Github secret, you need to change to your own one
> 2. You don't have to follow these Github actions, and design your prefer.
