#!/bin/bash

# DevOps Project Deployment Script
# Usage: ./scripts/deploy.sh [environment]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-staging}
PROJECT_NAME="devops-project"
DOCKER_REGISTRY="ghcr.io"
IMAGE_TAG=${GITHUB_SHA:-latest}

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Validate environment
validate_environment() {
    case $ENVIRONMENT in
        dev|staging|production)
            log "Deploying to ${ENVIRONMENT} environment"
            ;;
        *)
            error "Invalid environment: ${ENVIRONMENT}. Use: dev, staging, or production"
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
    fi
    
    # Check if kubectl is installed (for K8s deployments)
    if ! command -v kubectl &> /dev/null; then
        warning "kubectl is not installed - Kubernetes deployments will not work"
    fi
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        warning "Terraform is not installed - Infrastructure deployments will not work"
    fi
    
    success "Prerequisites check completed"
}

# Build Docker image
build_image() {
    log "Building Docker image..."
    
    docker build -t ${PROJECT_NAME}:${IMAGE_TAG} .
    docker tag ${PROJECT_NAME}:${IMAGE_TAG} ${PROJECT_NAME}:latest
    
    success "Docker image built successfully"
}

# Deploy infrastructure
deploy_infrastructure() {
    log "Deploying infrastructure for ${ENVIRONMENT}..."
    
    cd infrastructure/terraform
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -var="environment=${ENVIRONMENT}" -out=tfplan
    
    # Apply changes
    terraform apply tfplan
    
    cd ../..
    
    success "Infrastructure deployed successfully"
}

# Deploy application
deploy_application() {
    log "Deploying application to ${ENVIRONMENT}..."
    
    case $ENVIRONMENT in
        dev)
            deploy_dev
            ;;
        staging)
            deploy_staging
            ;;
        production)
            deploy_production
            ;;
    esac
}

# Development deployment (Docker Compose)
deploy_dev() {
    log "Starting development environment with Docker Compose..."
    
    docker-compose down
    docker-compose up -d --build
    
    # Wait for services to be ready
    sleep 10
    
    # Health check
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        success "Development environment is running at http://localhost:3000"
    else
        error "Development environment failed to start"
    fi
}

# Staging deployment
deploy_staging() {
    log "Deploying to staging environment..."
    
    # Deploy to staging cluster (example with kubectl)
    if command -v kubectl &> /dev/null; then
        kubectl apply -f infrastructure/kubernetes/staging/
        kubectl rollout status deployment/${PROJECT_NAME} -n staging
        success "Staging deployment completed"
    else
        warning "kubectl not available - simulating staging deployment"
        sleep 3
        success "Staging deployment simulated"
    fi
}

# Production deployment
deploy_production() {
    log "Deploying to production environment..."
    
    # Additional safety checks for production
    read -p "Are you sure you want to deploy to PRODUCTION? (yes/no): " confirm
    if [[ $confirm != "yes" ]]; then
        error "Production deployment cancelled"
    fi
    
    # Deploy to production cluster
    if command -v kubectl &> /dev/null; then
        kubectl apply -f infrastructure/kubernetes/production/
        kubectl rollout status deployment/${PROJECT_NAME} -n production
        success "Production deployment completed"
    else
        warning "kubectl not available - simulating production deployment"
        sleep 5
        success "Production deployment simulated"
    fi
}

# Run health checks
health_check() {
    log "Running health checks..."
    
    case $ENVIRONMENT in
        dev)
            HEALTH_URL="http://localhost:3000/health"
            ;;
        staging)
            HEALTH_URL="https://staging.devops-project.com/health"
            ;;
        production)
            HEALTH_URL="https://devops-project.com/health"
            ;;
    esac
    
    # Wait for application to be ready
    for i in {1..30}; do
        if curl -f $HEALTH_URL > /dev/null 2>&1; then
            success "Health check passed - Application is running"
            return 0
        fi
        log "Waiting for application to be ready... (${i}/30)"
        sleep 10
    done
    
    error "Health check failed - Application is not responding"
}

# Rollback function
rollback() {
    log "Rolling back deployment..."
    
    case $ENVIRONMENT in
        staging|production)
            if command -v kubectl &> /dev/null; then
                kubectl rollout undo deployment/${PROJECT_NAME} -n ${ENVIRONMENT}
                success "Rollback completed"
            else
                warning "kubectl not available - cannot rollback"
            fi
            ;;
        dev)
            docker-compose down
            success "Development environment stopped"
            ;;
    esac
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    rm -f infrastructure/terraform/tfplan
    success "Cleanup completed"
}

# Main deployment function
main() {
    log "Starting deployment process..."
    
    validate_environment
    check_prerequisites
    
    # Handle rollback option
    if [[ "${2}" == "--rollback" ]]; then
        rollback
        exit 0
    fi
    
    # Trap to cleanup on exit
    trap cleanup EXIT
    
    build_image
    
    # Deploy infrastructure for staging/production
    if [[ $ENVIRONMENT != "dev" ]]; then
        deploy_infrastructure
    fi
    
    deploy_application
    health_check
    
    success "Deployment to ${ENVIRONMENT} completed successfully! 🚀"
}

# Run main function
main "$@"