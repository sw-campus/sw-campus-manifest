# OpenTelemetry + Prometheus + Loki + Tempo + Grafana 통합 모니터링

이 디렉토리는 OpenTelemetry를 기반으로 한 통합 모니터링 스택을 구성합니다.

## 구성 요소

### 1. OpenTelemetry Collector
- **역할**: 메트릭, 로그, 트레이스를 수집하고 각 백엔드로 전송
- **엔드포인트**: 
  - OTLP gRPC: `otel-collector:4317`
  - OTLP HTTP: `otel-collector:4318`

### 2. Prometheus
- **역할**: 메트릭 저장 및 쿼리
- **접속**: `http://prometheus:9090`

### 3. Loki
- **역할**: 로그 수집 및 저장
- **접속**: `http://loki:3100`

### 4. Tempo
- **역할**: 분산 트레이싱 데이터 저장
- **접속**: `http://tempo:3200`

### 5. Grafana
- **역할**: 모든 데이터 시각화 및 대시보드
- **접속**: `http://localhost:3001` (SSH 터널링 필요)

## 배포 방법

### 1. 네임스페이스 생성
```bash
kubectl create namespace monitoring
```

### 2. 모니터링 스택 배포
```bash
# OpenTelemetry Collector (RBAC 권한 포함)
kubectl apply -f config/otel-collector-config.yaml
kubectl apply -f monitoring/otel-collector-rbac.yaml
kubectl apply -f monitoring/otel-collector-deployment.yaml

# Prometheus
kubectl apply -f config/prometheus-config.yaml
kubectl apply -f monitoring/prometheus-deployment.yaml

# Loki
kubectl apply -f config/loki-config.yaml
kubectl apply -f monitoring/loki-deployment.yaml

# Tempo
kubectl apply -f config/tempo-config.yaml
kubectl apply -f monitoring/tempo-deployment.yaml
```

### 3. Grafana 데이터소스 설정
```bash
kubectl apply -f monitoring/grafana-datasources.yaml
```

**또는 Grafana UI에서 수동 설정:**
1. Grafana 접속 (`http://localhost:3001`)
2. Configuration > Data Sources
3. 다음 데이터소스 추가:
   - **Prometheus**: `http://prometheus:9090`
   - **Loki**: `http://loki:3100`
   - **Tempo**: `http://tempo:3200`

## Spring Boot 애플리케이션 설정

애플리케이션은 이미 OpenTelemetry 설정이 완료되어 있습니다:

- `application.yml`에 OpenTelemetry 설정 포함
- `build.gradle`에 필요한 의존성 추가
- Logback에 OpenTelemetry appender 추가

## 데이터 흐름

```
Spring Boot App
    ↓ (OTLP)
OpenTelemetry Collector
    ├─ k8sattributes processor (K8s 메타데이터 자동 추가)
    ├─ resource processor (라벨링 개선)
    └─ transform processor (메트릭 정규화)
    ↓        ↓        ↓
Prometheus  Loki    Tempo
    ↓        ↓        ↓
    Grafana (통합 시각화 + Correlation)
```

## 주요 개선 사항

### 1. OpenTelemetry Collector 설정 개선
- **k8sattributes processor**: Kubernetes 메타데이터(pod, namespace, deployment 등) 자동 추가
- **resource processor**: 서비스 이름, 네임스페이스 등 리소스 속성 개선
- **transform processor**: 메트릭 이름 정규화 및 변환
- **개선된 라벨링**: Loki와 Prometheus로 전송되는 데이터에 더 풍부한 라벨 추가

### 2. Grafana 데이터소스 Correlation
- **Traces to Logs**: 트레이스에서 해당 로그로 바로 이동 가능
- **Traces to Metrics**: 트레이스에서 관련 메트릭으로 바로 이동 가능
- **UID 설정**: 각 데이터소스에 고유 UID 부여로 correlation 활성화
- **사전 정의된 메트릭 쿼리**: Request Rate, Error Rate, P50/P95/P99 Latency

### 3. Prometheus 서비스 디스커버리
- **Kubernetes Pod 자동 스크랩**: `prometheus.io/scrape: "true"` annotation이 있는 Pod 자동 발견
- **동적 라벨링**: Pod, Namespace, Container 정보 자동 라벨링
- **백업 스크랩 설정**: 서비스 디스커버리 실패 시 직접 설정된 타겟 사용

## 확인 방법

### 1. Pod 상태 확인
```bash
kubectl get pods -n monitoring
```

### 2. 서비스 확인
```bash
kubectl get svc -n monitoring
```

### 3. Grafana에서 확인

#### 메트릭 조회 (Prometheus)
1. Grafana 접속 후 **Explore** 메뉴 선택
2. 데이터소스로 **Prometheus** 선택
3. 예시 쿼리:
   ```promql
   # HTTP 요청 수
   sum(rate(http_server_request_duration_count[5m])) by (service_name, http_method)
   
   # 에러율
   sum(rate(http_server_request_duration_count{http_status_code=~"5.."}[5m])) by (service_name)
   
   # 응답 시간 (P95)
   histogram_quantile(0.95, sum(rate(http_server_request_duration_bucket[5m])) by (le, service_name))
   ```

#### 로그 조회 (Loki)
1. **Explore** 메뉴에서 데이터소스로 **Loki** 선택
2. 예시 쿼리:
   ```logql
   # 특정 서비스의 에러 로그
   {service_name="sw-campus-server"} |= "ERROR"
   
   # HTTP 5xx 에러
   {service_name="sw-campus-server"} | json | http_status_code >= 500
   
   # 특정 시간대 로그
   {namespace="default"} | json | timestamp >= "2024-01-01T00:00:00Z"
   ```

#### 트레이스 조회 (Tempo)
1. **Explore** 메뉴에서 데이터소스로 **Tempo** 선택
2. **Search** 탭에서 서비스 이름으로 검색
3. 트레이스 클릭 시:
   - **Logs** 버튼: 해당 트레이스의 로그로 바로 이동
   - **Metrics** 버튼: 해당 트레이스의 메트릭으로 바로 이동
   - **Node Graph**: 서비스 간 의존성 시각화

#### 통합 모니터링
- **Explore** 메뉴에서 여러 데이터소스를 동시에 조회 가능
- 트레이스에서 로그/메트릭으로 바로 이동하는 **Correlation** 기능 활용
- **Dashboard** 생성 시 여러 데이터소스의 패널을 함께 사용 가능

## 포트 포워딩

현재 Grafana는 포트 포워딩으로 접속 중입니다. 다른 서비스도 필요 시 포트 포워딩:

```bash
# Prometheus
kubectl port-forward svc/prometheus -n monitoring 9090:9090 &

# Loki
kubectl port-forward svc/loki -n monitoring 3100:3100 &

# Tempo
kubectl port-forward svc/tempo -n monitoring 3200:3200 &
```

## 애플리케이션 설정

### Spring Boot 애플리케이션에 Prometheus 스크랩 활성화

Pod에 다음 annotation을 추가하면 Prometheus가 자동으로 스크랩합니다:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/actuator/prometheus"
```

### OpenTelemetry 설정 확인

애플리케이션에서 OpenTelemetry Collector로 데이터를 전송하는지 확인:
- OTLP 엔드포인트: `otel-collector:4317` (gRPC) 또는 `otel-collector:4318` (HTTP)
- `application.yml`에 OpenTelemetry 설정이 포함되어 있는지 확인

## 트러블슈팅

### OpenTelemetry Collector가 Kubernetes 메타데이터를 수집하지 않는 경우
1. ServiceAccount와 RBAC 권한 확인:
   ```bash
   kubectl get serviceaccount otel-collector -n monitoring
   kubectl get clusterrolebinding otel-collector
   ```
2. Pod 로그 확인:
   ```bash
   kubectl logs -n monitoring deployment/otel-collector
   ```

### Prometheus가 메트릭을 스크랩하지 않는 경우
1. Prometheus 타겟 확인:
   ```bash
   kubectl port-forward svc/prometheus -n monitoring 9090:9090
   # 브라우저에서 http://localhost:9090/targets 접속
   ```
2. Pod annotation 확인:
   ```bash
   kubectl get pod <pod-name> -o yaml | grep prometheus.io
   ```

### Grafana에서 데이터소스 연결 실패
1. 서비스 이름 확인:
   ```bash
   kubectl get svc -n monitoring
   ```
2. 네트워크 정책 확인 (필요시)

## 참고 자료

- [OpenTelemetry 공식 문서](https://opentelemetry.io/docs/)
- [Grafana 공식 문서](https://grafana.com/docs/)
- [Prometheus 공식 문서](https://prometheus.io/docs/)
- [Loki 공식 문서](https://grafana.com/docs/loki/latest/)
- [Tempo 공식 문서](https://grafana.com/docs/tempo/latest/)

