#!/bin/bash

# 쿠버네티스 배포 스크립트
# 사용법: ./deploy.sh [client|server|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/../../config" && pwd)"

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# kubectl 설치 확인
if ! command -v kubectl &> /dev/null; then
    echo_error "kubectl이 설치되어 있지 않습니다."
    exit 1
fi

# kubectl 연결 확인
if ! kubectl cluster-info &> /dev/null; then
    echo_error "kubectl이 클러스터에 연결되지 않았습니다."
    exit 1
fi

echo_info "쿠버네티스 클러스터 연결 확인 완료"

# ConfigMap 적용 (ArgoCD가 자동으로 관리하지만, 초기 설정 시 필요)
echo_info "ConfigMap 적용 중..."
kubectl apply -f "$SCRIPT_DIR/config/" || echo_warn "일부 ConfigMap 적용 실패"

# Secret 파일 적용 (config 디렉토리에서 - 프라이빗 레포)
# ⚠️ Secret은 Git에 커밋되지 않으므로 수동으로 적용해야 합니다
if [ -f "$CONFIG_DIR/server-secret.yaml" ]; then
    echo_info "Secret 파일 적용 중 (프라이빗 레포: config/server-secret.yaml)..."
    kubectl apply -f "$CONFIG_DIR/server-secret.yaml" || echo_warn "Secret 적용 실패"
    echo_info "✅ Secret이 적용되었습니다. 이후 Secret 변경 시에만 이 스크립트를 실행하세요."
else
    echo_warn "Secret 파일을 찾을 수 없습니다: $CONFIG_DIR/server-secret.yaml"
    echo_warn "config 레포지토리를 확인하거나 submodule을 업데이트하세요."
fi

# PostgreSQL 서비스 확인 및 적용
if [ -f "$SCRIPT_DIR/database/postgres-external-service.yaml" ]; then
    echo_info "PostgreSQL 서비스 확인 중..."
    if ! kubectl get service postgres-service -n default &> /dev/null; then
        echo_warn "PostgreSQL 서비스가 없습니다. postgres-external-service.yaml을 수정하고 적용하세요."
    fi
fi

# 배포 타입에 따라 적용
DEPLOY_TYPE=${1:-all}

case $DEPLOY_TYPE in
    client)
        echo_info "클라이언트 배포 중..."
        kubectl apply -f "$SCRIPT_DIR/client/"
        ;;
    server)
        echo_info "서버 배포 중..."
        kubectl apply -f "$SCRIPT_DIR/server/"
        ;;
    all)
        echo_info "전체 애플리케이션 배포 중..."
        kubectl apply -f "$SCRIPT_DIR/server/"
        kubectl apply -f "$SCRIPT_DIR/client/"
        ;;
    *)
        echo_error "잘못된 인자: $DEPLOY_TYPE"
        echo "사용법: $0 [client|server|all]"
        exit 1
        ;;
esac

# 배포 상태 확인
echo_info "배포 상태 확인 중..."
kubectl get pods -n default -l app=sw-campus-server || true
kubectl get pods -n default -l app=sw-campus-client || true

echo_info "배포 완료!"
echo ""
echo_info "📌 참고사항:"
echo_info "  - ConfigMap 변경은 ArgoCD가 자동으로 감지하여 배포합니다"
echo_info "  - Secret 변경이 필요한 경우에만 이 스크립트를 실행하세요"
echo_info "  - 일반적인 애플리케이션 배포는 ArgoCD가 자동으로 처리합니다"

