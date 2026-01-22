# Monitoring Chart Context

## Loki 마이그레이션 히스토리

### 2026-01-21: 공식 Helm Chart 마이그레이션

**변경 사항:**
- 커스텀 템플릿 3개 삭제 → grafana/loki 6.23.0 의존성 사용
- 배포 모드: SingleBinary
- 서비스 이름 유지: `monitoring-loki`

**삭제된 파일:**
- `templates/loki-configmap.yaml`
- `templates/loki-deployment.yaml`
- `templates/loki-service.yaml`

---

## 트러블슈팅 가이드

### 1. otlp_config 파싱 오류

**증상:**
```
failed parsing config: yaml: unmarshal errors:
  cannot unmarshal !!seq into push.ResourceAttributesConfig
```

**원인:** Loki 3.x에서 `otlp_config` 형식 변경

**해결:** `otlp_config` 섹션 제거 (OTel Collector가 HTTP API로 전송)

---

### 2. 불필요한 컴포넌트 생성

**증상:** `loki-canary`, `chunks-cache`, `results-cache` Pod 생성

**원인:** Helm Chart 기본값이 분산 모드 컴포넌트 활성화

**해결:**
```yaml
chunksCache:
  enabled: false
resultsCache:
  enabled: false
lokiCanary:
  enabled: false
monitoring:
  lokiCanary:
    enabled: false
```

**주의:** `lokiCanary`는 최상위 레벨과 `monitoring` 하위 모두에서 비활성화 필요

---

### 3. Gateway 503 오류

**증상:** Loki API 접근 시 503 Service Unavailable

**원인:** SingleBinary 모드에서 Gateway 불필요

**해결:**
```yaml
gateway:
  enabled: false
```

---

### 4. Pod CrashLoopBackOff

**진단 순서:**
```bash
# 1. Pod 상태 확인
kubectl get pods -n monitoring | grep loki

# 2. 로그 확인
kubectl logs -n monitoring monitoring-loki-0 -c loki

# 3. ConfigMap 확인
kubectl get configmap -n monitoring loki -o yaml
```

**일반적 원인:**
- Config 파싱 오류 → 설정 형식 확인
- 리소스 부족 → limits 조정
- PVC 마운트 실패 → StorageClass 확인

---

## 버전 업그레이드 체크리스트

Loki Helm Chart 업그레이드 시:

- [ ] CHANGELOG 확인 (breaking changes)
- [ ] `helm show values` 로 기본값 변경 확인
- [ ] `helm template --dry-run` 으로 생성 리소스 검증
- [ ] 개발 환경에서 먼저 테스트
- [ ] 캐시/Canary 컴포넌트 비활성화 유지 확인
- [ ] OTLP 엔드포인트 동작 확인

---

## 관련 파일

- `Chart.yaml` - 의존성 버전
- `values.yaml` - 기본 설정 (운영 기준)
- `../environments/develop-monitoring/values.yaml` - 개발 환경 오버라이드
- `../environments/release-monitoring/values.yaml` - 운영 환경 오버라이드
