#!/bin/bash
# Terraform Plan 스크립트
# config 폴더의 환경변수 파일을 자동으로 읽어서 계획 확인

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../" && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config/terraform-prod.tfvars"
ENV_FILE="$PROJECT_ROOT/config/terraform-prod.env"

# config/terraform-prod.tfvars 파일이 있으면 사용
if [ -f "$CONFIG_FILE" ]; then
    echo "📁 Using config/terraform-prod.tfvars"
    terraform plan -var-file="$CONFIG_FILE" "$@"
# config/terraform-prod.env 파일이 있으면 환경변수로 로드
elif [ -f "$ENV_FILE" ]; then
    echo "📁 Using config/terraform-prod.env"
    source "$ENV_FILE"
    terraform plan "$@"
# 둘 다 없으면 기본 terraform.tfvars 사용
elif [ -f "$SCRIPT_DIR/terraform.tfvars" ]; then
    echo "📁 Using local terraform.tfvars"
    terraform plan "$@"
else
    echo "❌ Error: No configuration file found!"
    echo "Please create one of:"
    echo "  - config/terraform-prod.tfvars"
    echo "  - config/terraform-prod.env"
    echo "  - terraform.tfvars (in current directory)"
    exit 1
fi

