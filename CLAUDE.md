# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **GitOps manifest repository** for the SW Campus application. Changes merged here are automatically deployed to Kubernetes clusters via ArgoCD.

**CRITICAL**: This repository controls live deployments. All changes directly affect running services.

## Architecture

### Branch-Based Environments

- `develop` branch → Development environment (VM-based Kubernetes)
- `main` branch → Production environment (AWS EKS)

### Service Components

Three microservices are deployed:
- **Server** (`ghcr.io/sw-campus/sw-campus-server`): Backend API on port 8080
- **Client** (`ghcr.io/sw-campus/sw-campus-client`): Frontend on port 3000
- **AI** (`ghcr.io/sw-campus/sw-campus-ai`): AI service on port 8000

### Repository Structure

```
k8s/
├── charts/
│   ├── sw-campus/          # Main application Helm chart
│   │   ├── templates/      # K8s manifests (deployments, services, configmaps)
│   │   └── values.yaml     # Default values
│   └── monitoring/         # Observability stack (Prometheus, Loki, Grafana, Tempo, OpenTelemetry)
└── environments/
    ├── develop/            # Dev environment overrides
    │   ├── values.yaml     # Image tags updated by CI/CD
    │   └── application.yaml # ArgoCD Application definition
    ├── develop-monitoring/
    ├── release/            # Production overrides
    └── release-monitoring/
```

### Deployment Flow (GitOps)

1. Service repositories (server/client/ai) build and push Docker images to GHCR with commit SHA tags
2. GitHub Actions workflow (`update-develop-image-tags.yml`) runs hourly to:
   - Check latest commit SHAs from service repositories
   - Verify Docker images exist in GHCR
   - Update `k8s/environments/develop/values.yaml` with new image tags
   - Commit changes directly to `develop` branch
3. ArgoCD detects changes and syncs to Kubernetes (polls every 3 minutes)

### ArgoCD Configuration

Each environment has an ArgoCD Application manifest that:
- Points to this repository's specific branch
- Uses Helm chart from `k8s/charts/sw-campus` or `k8s/charts/monitoring`
- Overlays environment-specific values from `k8s/environments/{env}/values.yaml`
- Has `automated: {prune: true, selfHeal: true}` for automatic sync

## Common Commands

### Image Tag Updates

Manual image tag update (not typically needed - CI/CD handles this):
```bash
# Edit the values file for the target environment
vim k8s/environments/develop/values.yaml

# Update the tag field for the service:
# server.image.tag: "abc1234"
# client.image.tag: "def5678"
# ai.image.tag: "ghi9012"
```

### Checking Deployment Status

```bash
# View current image tags in develop environment
cat k8s/environments/develop/values.yaml | grep -A2 "repository:"

# Check git history for recent deployments
git log --oneline -10

# View workflow runs (check CI/CD status)
gh run list --workflow=update-develop-image-tags.yml
```

### Rollback

To rollback a deployment:
```bash
# Find the commit with the working image tags
git log --oneline k8s/environments/develop/values.yaml

# Create a new branch from current state
git checkout -b rollback-to-COMMIT_SHA

# Reset values.yaml to the previous working state
git checkout COMMIT_SHA -- k8s/environments/develop/values.yaml

# Create PR to merge the rollback
gh pr create --base develop --title "Rollback to COMMIT_SHA"
```

### Monitoring Stack

Monitoring is deployed separately from the main application:
- Charts: `k8s/charts/monitoring/`
- Components: Grafana, Prometheus, Loki, Promtail, Tempo, OpenTelemetry Collector
- Namespace: `monitoring`

## Important Rules

1. **Never commit directly to `main`** - Production changes require PR approval
2. **Image tags must exist in GHCR** - The workflow validates image existence before updating
3. **Don't manually apply manifests** - Let ArgoCD handle deployments (GitOps principle)
4. **Secrets are not in this repo** - They're managed separately via external config repository
5. **ConfigMap changes are auto-deployed** - Merged changes sync within 3 minutes via ArgoCD

## Configuration Management

### Values File Hierarchy

1. Base values: `k8s/charts/sw-campus/values.yaml`
2. Environment overrides: `k8s/environments/{env}/values.yaml`

Environment values take precedence and typically override:
- Image tags (managed by CI/CD)
- Replica counts
- Resource limits
- Environment-specific ConfigMap data (e.g., `SPRING_PROFILES_ACTIVE: staging`)

### Image Tag Format

- Development: Short commit SHA (7 characters) or `develop` fallback
- Production: Semantic version tags expected

### Secrets

Secrets are NOT stored in this repository. They are managed via:
- External private config repository
- Manual `kubectl apply` for secret updates
- Referenced in deployments via `secretRef` pointing to pre-existing secrets

## Helm Chart Structure

The main chart (`k8s/charts/sw-campus`) uses conditional rendering:
- Each service can be enabled/disabled via `{service}.enabled` flag
- Common patterns: Deployment + Service + ConfigMap per microservice
- Shared configuration: `global.namespace`, `global.imagePullSecrets`

Template files follow naming: `{service}-{resource-type}.yaml`

## GitHub Actions Workflows

### update-develop-image-tags.yml
- **Trigger**: Hourly cron + manual dispatch
- **Purpose**: Auto-update develop environment with latest service images
- **Behavior**:
  - Fetches latest commit SHAs from service repos
  - Validates images exist in GHCR (falls back to "develop" tag if missing)
  - Updates `k8s/environments/develop/values.yaml` with sed commands
  - Commits directly to develop branch (no PR)

### update-develop-images.yml
- Legacy workflow - verify if still in use before modifying
