> ⚠️ This repository follows GitOps principles.  
> Any change merged into this repository will be deployed automatically.


---

## 🌱 Branch Strategy

이 레포지토리는 **브랜치 단위로 배포 환경을 분리**합니다.

| Branch   | Environment | Cluster |
|--------|-------------|---------|
| develop | Development | VM-based Kubernetes |
| main   | Production  | AWS EKS |

- `develop` : 개발/테스트 환경 배포
- `main` : 실제 운영 환경 배포
- 모든 변경은 Pull Request를 통해서만 반영됩니다.

---

## 🚀 Deployment Flow (GitOps)

1. 각 서비스 레포(server / client / ai)에서 코드 변경 발생
2. GitHub Actions가 Docker 이미지를 빌드하여 GHCR에 Push
3. GitHub Actions가 **이 레포지토리에 Pull Request 생성**
    - Deployment YAML의 `image` 태그만 변경
4. PR Merge 시 ArgoCD가 변경 사항을 감지
5. Kubernetes 클러스터에 자동 배포

---

## 🔁 Rollback Strategy

- 모든 배포는 Git 이력으로 관리됩니다.
- 장애 발생 시:
    - 이전 이미지 태그로 되돌리는 PR을 생성하여 롤백
- 서비스 단위(server / client / ai)로 독립적인 롤백 가능

---

## ⚠️ Rules

- 이 레포지토리의 변경은 **실제 서비스 배포로 직결**됩니다.
- `main` 브랜치에 직접 push 금지
- 반드시 Pull Request를 통해 변경해야 합니다.
- Kubernetes 리소스는 **ArgoCD를 통해서만 관리**합니다.
- 운영 환경에서는 `kubectl apply`를 직접 사용하지 않습니다.


## 📊 Observability
> 📌 Observability 설정은 배포와 분리된 운영 문서로 관리합니다.

본 레포지토리는 OpenTelemetry 기반의 통합 모니터링 스택을 포함합니다.

- Metrics: Prometheus
- Logs: Loki
- Traces: Tempo
- Visualization: Grafana

👉 자세한 구성 및 운영 방법은  
[`monitoring/README.md`](./monitoring/README.md)를 참고하세요.
