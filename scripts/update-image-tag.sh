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

# sw-campus-server 저장소에서 최신 커밋 SHA 가져오기
if [ "$SERVICE" = "server" ]; then
    SERVER_DIR="$MANIFEST_DIR/../sw-campus-server"
    if [ ! -d "$SERVER_DIR" ]; then
        echo "Error: sw-campus-server directory not found at $SERVER_DIR"
        echo "Please ensure sw-campus-server is in the same parent directory"
        exit 1
    fi
    
    cd "$SERVER_DIR"
    COMMIT_SHA=$(git rev-parse --short HEAD)
    NEW_TAG="v1.0.0-${COMMIT_SHA}"
    
    # values.yaml 업데이트
    cd "$MANIFEST_DIR"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|tag: v1.0.0-.*|tag: ${NEW_TAG}|" "$VALUES_FILE"
    else
        # Linux
        sed -i "s|tag: v1.0.0-.*|tag: ${NEW_TAG}|" "$VALUES_FILE"
    fi
    
    echo "✅ Updated server image tag to: $NEW_TAG"
    echo "📝 Commit SHA: $COMMIT_SHA"
    echo ""
    echo "⚠️  Don't forget to commit this change:"
    echo "   git add k8s/environments/release/values.yaml"
    echo "   git commit -m \"chore: update server image tag to ${NEW_TAG}\""
else
    echo "Error: Only 'server' service is supported for now"
    exit 1
fi

