# aim-ahead-infra

## Install hook locally

### 1. Install with brew

```bash
brew install pre-commit tflint tfsec trivy checkov
```

### 2. Install the git hook scripts

Go to root direcotry of project

```bash
pre-commit install
```

- now pre-commit will run automatically on git commit!

### 3. (Optional) Run against all the files

It's usually a good idea to run the hooks against all of the files when adding new hooks (usually pre-commit will only run on the changed files during git hooks)

```bash
pre-commit run -a
```
