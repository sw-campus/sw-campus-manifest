#!/bin/bash

# 배포 문제 해결 스크립트

set -e

NAMESPACE="develop"

echo "=== 1. 서버 Secret 확인 및 생성 ==="
if kubectl get secret sw-campus-server-secret -n "$NAMESPACE" &>/dev/null; then
  echo "✅ sw-campus-server-secret이 이미 존재합니다."
else
  echo "⚠️  sw-campus-server-secret이 없습니다. 생성이 필요합니다."
  echo ""
  echo "다음 중 하나를 선택하세요:"
  echo "1. config/server-secret.yaml 파일이 있다면:"
  echo "   kubectl apply -f config/server-secret.yaml -n $NAMESPACE"
  echo ""
  echo "2. 직접 생성 (임시 값):"
  echo "   kubectl create secret generic sw-campus-server-secret \\"
  echo "     --from-literal=SPRING_DATASOURCE_PASSWORD=CHANGE_ME \\"
  echo "     --from-literal=JWT_SECRET=CHANGE_ME \\"
  echo "     --from-literal=AWS_ACCESS_KEY=CHANGE_ME \\"
  echo "     --from-literal=AWS_SECRET_KEY=CHANGE_ME \\"
  echo "     --from-literal=GOOGLE_CLIENT_SECRET=CHANGE_ME \\"
  echo "     --from-literal=GITHUB_CLIENT_SECRET=CHANGE_ME \\"
  echo "     --from-literal=MAIL_USERNAME=CHANGE_ME \\"
  echo "     --from-literal=MAIL_PASSWORD=CHANGE_ME \\"
  echo "     -n $NAMESPACE"
  echo ""
  read -p "config/server-secret.yaml 파일이 있나요? (y/n): " has_secret_file
  if [ "$has_secret_file" = "y" ]; then
    if [ -f "config/server-secret.yaml" ]; then
      kubectl apply -f config/server-secret.yaml -n "$NAMESPACE"
      echo "✅ Secret이 생성되었습니다."
    else
      echo "❌ config/server-secret.yaml 파일을 찾을 수 없습니다."
      exit 1
    fi
  else
    echo "수동으로 Secret을 생성해주세요."
  fi
fi

echo ""
echo "=== 2. AI Pod 재생성 (imagePullSecrets 수정사항 적용) ==="
echo "AI Pod를 삭제하여 새로운 설정으로 재생성합니다..."
kubectl delete pods -n "$NAMESPACE" -l app=sw-campus-ai --ignore-not-found=true
echo "✅ AI Pod 삭제 완료. Deployment가 자동으로 재생성합니다."

echo ""
echo "=== 3. 서버 Pod 재생성 (Secret 적용) ==="
kubectl delete pods -n "$NAMESPACE" -l app=sw-campus-server --ignore-not-found=true
echo "✅ 서버 Pod 삭제 완료. Deployment가 자동으로 재생성합니다."

echo ""
echo "=== 4. 상태 확인 ==="
echo "잠시 후 Pod 상태를 확인합니다..."
sleep 5
kubectl get pods -n "$NAMESPACE"

echo ""
echo "=== 완료 ==="
echo "Pod 상태를 확인하려면: kubectl get pods -n $NAMESPACE"
echo "Pod 이벤트를 확인하려면: kubectl describe pod -n $NAMESPACE -l app=sw-campus-server"

