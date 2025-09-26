# Deployment Guide

This document outlines the deployment process for the DevOps project across different environments.

## Overview

Our deployment strategy follows GitFlow principles with automated CI/CD pipelines:

- **Development**: Local Docker Compose environment
- **Staging**: Kubernetes cluster with automated deployments from `develop` branch
- **Production**: Kubernetes cluster with automated deployments from `main` branch

## Prerequisites

### Required Tools
- Docker & Docker Compose
- kubectl (for Kubernetes deployments)
- Terraform (for infrastructure management)
- Git
- Node.js 18+

### Required Access
- GitHub repository access
- Container registry access (GitHub Container Registry)
- Cloud provider access (AWS)
- Kubernetes cluster access

## Environment Configuration

### Development Environment

1. **Setup local environment:**
```bash
# Clone repository
git clone https://github.com/[username]/devops-project.git
cd devops-project

# Install dependencies
npm install

# Start development environment
docker-compose up -d
```

2. **Verify deployment:**
```bash
# Check application health
curl http://localhost:3000/health

# View logs
docker-compose logs -f app
```

### Staging Environment

Staging deployments are triggered automatically when code is pushed to the `develop` branch.

1. **Manual deployment:**
```bash
# Deploy to staging
./scripts/deploy.sh staging
```

2. **Verify deployment:**
```bash
# Check deployment status
kubectl get deployments -n staging

# Check pod status
kubectl get pods -n staging

# View logs
kubectl logs -f deployment/devops-project -n staging
```

### Production Environment

Production deployments are triggered automatically when code is pushed to the `main` branch.

1. **Manual deployment:**
```bash
# Deploy to production (requires confirmation)
./scripts/deploy.sh production
```

2. **Verify deployment:**
```bash
# Check deployment status
kubectl get deployments -n production

# Check service status
kubectl get services -n production

# Run health checks
curl https://devops-project.com/health
```

## Infrastructure Management

### Terraform Deployment

1. **Initialize Terraform:**
```bash
cd infrastructure/terraform
terraform init
```

2. **Plan infrastructure changes:**
```bash
terraform plan -var="environment=staging"
```

3. **Apply infrastructure changes:**
```bash
terraform apply -var="environment=staging"
```

4. **Destroy infrastructure (if needed):**
```bash
terraform destroy -var="environment=staging"
```

### Infrastructure Components

- **VPC**: Isolated network environment
- **Subnets**: Public and private subnets across multiple AZs
- **Load Balancer**: Application Load Balancer for traffic distribution
- **ECS Cluster**: Container orchestration platform
- **Security Groups**: Network security rules
- **Auto Scaling**: Automatic scaling based on demand

## CI/CD Pipeline

### Pipeline Stages

1. **Code Quality Checks**
   - ESLint for code linting
   - Prettier for code formatting
   - Unit tests with Jest
   - Code coverage reporting

2. **Security Scanning**
   - Dependency vulnerability scanning with Snyk
   - Container image security scanning
   - Infrastructure security checks

3. **Build & Package**
   - Docker image building
   - Multi-stage builds for optimization
   - Image tagging and versioning

4. **Deploy**
   - Staging deployment (develop branch)
   - Production deployment (main branch)
   - Health checks and verification

### Pipeline Configuration

The CI/CD pipeline is configured in `.github/workflows/ci-cd.yml` and includes:

- Automated testing on pull requests
- Security scanning for all branches
- Docker image building and publishing
- Environment-specific deployments
- Notification on success/failure

## Rollback Procedures

### Automatic Rollback

The deployment script includes automatic rollback capabilities:

```bash
# Rollback staging deployment
./scripts/deploy.sh staging --rollback

# Rollback production deployment
./scripts/deploy.sh production --rollback
```

### Manual Rollback

For Kubernetes deployments:

```bash
# View rollout history
kubectl rollout history deployment/devops-project -n production

# Rollback to previous version
kubectl rollout undo deployment/devops-project -n production

# Rollback to specific revision
kubectl rollout undo deployment/devops-project --to-revision=2 -n production
```

## Monitoring & Health Checks

### Application Health

- **Health Endpoint**: `/health`
- **Status Endpoint**: `/api/status`
- **Metrics**: Prometheus metrics collection
- **Logging**: Structured logging with correlation IDs

### Infrastructure Monitoring

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **CloudWatch**: AWS infrastructure monitoring
- **ELK Stack**: Centralized logging

### Alerting

Alerts are configured for:
- Application downtime
- High error rates
- Resource utilization thresholds
- Security incidents
- Deployment failures

## Troubleshooting

### Common Issues

1. **Container startup failures**
   - Check container logs: `docker logs <container_id>`
   - Verify environment variables
   - Check resource limits

2. **Database connection issues**
   - Verify database credentials
   - Check network connectivity
   - Review security group rules

3. **Load balancer health check failures**
   - Verify health endpoint response
   - Check target group configuration
   - Review security group rules

### Debug Commands

```bash
# Check application logs
kubectl logs -f deployment/devops-project -n <namespace>

# Describe pod for detailed information
kubectl describe pod <pod-name> -n <namespace>

# Execute commands in running container
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Check service endpoints
kubectl get endpoints -n <namespace>
```

## Security Considerations

### Container Security
- Non-root user execution
- Minimal base images
- Regular security updates
- Vulnerability scanning

### Network Security
- Private subnets for application tiers
- Security groups with least privilege
- TLS encryption in transit
- WAF protection

### Secrets Management
- Environment-specific secret stores
- Encrypted secrets at rest
- Regular secret rotation
- Access logging and auditing

## Best Practices

1. **Always test in staging first**
2. **Use feature flags for gradual rollouts**
3. **Monitor deployments closely**
4. **Keep rollback procedures ready**
5. **Document all changes**
6. **Regular security updates**
7. **Backup before major changes**
8. **Use infrastructure as code**