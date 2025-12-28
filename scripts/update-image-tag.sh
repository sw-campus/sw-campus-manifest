#!/bin/bash

# 이미지 태그를 커밋 SHA 기반으로 자동 업데이트하는 스크립트
# 사용법: ./scripts/update-image-tag.sh [server|client|ai]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VALUES_FILE="$MANIFEST_DIR/k8s/environments/release/values.yaml"

SERVICE=${1:-server}

if [ ! -f "$VALUES_FILE" ]; then
    echo "Error: $VALUES_FILE not found"
    exit 1
fi

# 서비스별 저장소 경로 및 설정
case "$SERVICE" in
    server)
        REPO_DIR="$MANIFEST_DIR/../sw-campus-server"
        REPO_NAME="sw-campus-server"
        SED_PATTERN="server:"
        ;;
    client)
        REPO_DIR="$MANIFEST_DIR/../sw-campus-client"
        REPO_NAME="sw-campus-client"
        SED_PATTERN="client:"
        ;;
    ai)
        REPO_DIR="$MANIFEST_DIR/../sw-campus-ai"
        REPO_NAME="sw-campus-ai"
        SED_PATTERN="ai:"
        ;;
    *)
        echo "Error: Unknown service '$SERVICE'"
        echo "Usage: $0 [server|client|ai]"
        exit 1
        ;;
esac

if [ ! -d "$REPO_DIR" ]; then
    echo "Error: $REPO_NAME directory not found at $REPO_DIR"
    echo "Please ensure $REPO_NAME is in the same parent directory"
    exit 1
fi

# 저장소에서 최신 커밋 SHA 가져오기
cd "$REPO_DIR"
COMMIT_SHA=$(git rev-parse --short HEAD)
NEW_TAG="v1.0.0-${COMMIT_SHA}"

# values.yaml 업데이트
cd "$MANIFEST_DIR"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - 서비스별 image 섹션에서 tag만 업데이트
    sed -i '' "/^  ${SED_PATTERN}/,/^  [a-z]/ {
        /^    tag:/ s|tag: v1.0.0.*|tag: ${NEW_TAG}|
    }" "$VALUES_FILE"
else
    # Linux - 서비스별 image 섹션에서 tag만 업데이트
    sed -i "/^  ${SED_PATTERN}/,/^  [a-z]/ {
        /^    tag:/ s|tag: v1.0.0.*|tag: ${NEW_TAG}|
    }" "$VALUES_FILE"
fi

echo "✅ Updated $SERVICE image tag to: $NEW_TAG"
echo "📝 Commit SHA: $COMMIT_SHA"
echo ""
echo "⚠️  Don't forget to commit this change:"
echo "   git add k8s/environments/release/values.yaml"
echo "   git commit -m \"chore: update $SERVICE image tag to ${NEW_TAG}\""

