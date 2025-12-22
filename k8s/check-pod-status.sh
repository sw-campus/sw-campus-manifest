#!/bin/bash

# Pod 상태 확인 스크립트

echo "=== 1. Argo CD Application 상태 확인 ==="
kubectl get application -n argocd sw-campus-develop

echo -e "\n=== 2. Pod 상태 확인 ==="
kubectl get pods -n develop

echo -e "\n=== 3. Pod의 imagePullSecrets 확인 ==="
echo "Server Pod:"
kubectl get pod -n develop -l app=sw-campus-server -o jsonpath='{.items[0].spec.imagePullSecrets}' 2>/dev/null | jq '.' || echo "No server pod found"
echo -e "\nClient Pod:"
kubectl get pod -n develop -l app=sw-campus-client -o jsonpath='{.items[0].spec.imagePullSecrets}' 2>/dev/null | jq '.' || echo "No client pod found"
echo -e "\nAI Pod:"
kubectl get pod -n develop -l app=sw-campus-ai -o jsonpath='{.items[0].spec.imagePullSecrets}' 2>/dev/null | jq '.' || echo "No AI pod found"

echo -e "\n=== 4. 최근 Pod 이벤트 확인 ==="
echo "Server Pod Events:"
kubectl describe pod -n develop -l app=sw-campus-server | grep -A 5 "Events:" | tail -10
echo -e "\nClient Pod Events:"
kubectl describe pod -n develop -l app=sw-campus-client | grep -A 5 "Events:" | tail -10
echo -e "\nAI Pod Events:"
kubectl describe pod -n develop -l app=sw-campus-ai | grep -A 5 "Events:" | tail -10

