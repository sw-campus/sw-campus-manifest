# Terraform 인프라 구성

## 개요

이 디렉토리는 AWS 프로덕션 환경 인프라를 Terraform으로 관리합니다.

## 구성 요소

- **VPC**: 10.0.0.0/16
  - Public Subnet (2개): ALB, NAT Gateway
  - Private Subnet (1개): EKS
- **ALB**: HTTP → HTTPS 리다이렉트, /api/* → Server, 나머지 → Client
- **EKS**: Kubernetes 클러스터
- **Route53**: 도메인 설정

**참고**: RDS와 MongoDB는 EC2에 컨테이너로 별도 배포 예정

## 사전 준비

### 1. 도메인 준비

- 도메인을 이미 구매했어야 합니다 (예: `softwarecampus.co.kr`)
- Terraform이 Route53 Hosted Zone과 ACM 인증서를 자동으로 생성합니다

### 2. 도메인 등록업체에 NS 레코드 등록 (중요!)

Terraform 적용 후 Route53 Name Servers를 도메인 등록업체에 등록해야 합니다.

```bash
# 1. Terraform 적용
terraform apply

# 2. 출력된 Name Servers 확인
terraform output route53_name_servers

# 3. 도메인 등록업체(가비아, 후이즈 등) 관리 페이지로 이동
# 4. DNS 설정 → 네임서버(Nameserver) 변경
# 5. Terraform 출력값의 NS 레코드 4개를 입력
# 6. 저장 (변경 반영까지 수 시간~최대 48시간 소요)
```

**참고**: NS 레코드 등록이 완료되어야 DNS가 정상 작동하고 ACM 인증서 검증이 완료됩니다.

## 설정 방법

### 방법 1: config 폴더 사용 (권장) ✅

프로젝트 루트의 `config/` 폴더에 환경변수 파일을 생성합니다.

#### 옵션 1-A: .tfvars 파일 사용

```bash
# 1. config 폴더에 템플릿 파일 복사
cp config/terraform-prod.tfvars.template config/terraform-prod.tfvars

# 2. config/terraform-prod.tfvars 파일 편집
# - domain_name: 실제 도메인 (예: "softwarecampus.co.kr")
# - certificate_arn은 자동 생성되므로 입력 불필요 ✅

# 3. 스크립트 사용 (자동으로 config 파일 읽음)
cd sw-campus-manifest/terraform/environments/prod
./apply.sh

# 또는 직접 지정
terraform apply -var-file=../../../config/terraform-prod.tfvars
```

#### 옵션 1-B: .env 파일 사용

```bash
# 1. config 폴더에 템플릿 파일 복사
cp config/terraform-prod.env.template config/terraform-prod.env

# 2. config/terraform-prod.env 파일 편집

# 3. 환경변수 로드 후 실행
source config/terraform-prod.env
cd sw-campus-manifest/terraform/environments/prod
terraform apply
```

### 방법 2: 로컬 terraform.tfvars 사용

```bash
# 1. config 폴더의 템플릿을 현재 디렉토리로 복사
cp ../../../config/terraform-prod.tfvars.template terraform.tfvars

# 2. terraform.tfvars 파일 편집

# 3. 실행
terraform apply
```

### 방법 3: 환경변수 직접 사용 (CI/CD 권장)

Terraform은 `TF_VAR_` prefix를 가진 환경변수를 자동으로 읽습니다.

```bash
export TF_VAR_domain_name="softwarecampus.co.kr"
# certificate_arn은 자동 생성되므로 입력 불필요 ✅

terraform apply
```

**GitHub Actions 예시:**
```yaml
env:
  TF_VAR_domain_name: ${{ secrets.DOMAIN_NAME }}
  # certificate_arn은 자동 생성되므로 secrets 불필요 ✅
```

### 우선순위

1. 환경변수 (`TF_VAR_*`)
2. `-var-file` 옵션으로 지정한 파일
3. `terraform.tfvars` (현재 디렉토리)
4. `config/terraform-prod.tfvars` (스크립트 사용 시)

## 실행 방법

### 스크립트 사용 (권장) ✅

```bash
cd sw-campus-manifest/terraform/environments/prod

# 1. Terraform 초기화 (최초 1회)
terraform init

# 2. 계획 확인 (변경사항 미리보기)
./plan.sh

# 3. 인프라 생성
./apply.sh

# 4. 인프라 삭제 (주의!)
terraform destroy -var-file=../../../config/terraform-prod.tfvars
```

### 직접 실행

```bash
cd sw-campus-manifest/terraform/environments/prod

# 1. Terraform 초기화
terraform init

# 2. 계획 확인
terraform plan -var-file=../../../config/terraform-prod.tfvars

# 3. 인프라 생성
terraform apply -var-file=../../../config/terraform-prod.tfvars

# 4. 인프라 삭제 (주의!)
terraform destroy -var-file=../../../config/terraform-prod.tfvars
```

## 출력 값 확인

```bash
terraform output
```

주요 출력:
- `vpc_id`: VPC ID
- `alb_dns_name`: ALB DNS 이름
- `eks_cluster_id`: EKS 클러스터 ID
- `route53_zone_id`: Route53 Zone ID
- `route53_name_servers`: Route53 Name Servers (도메인 등록업체에 등록 필요) ⚠️
- `acm_certificate_arn`: ACM 인증서 ARN (자동 생성됨) ✅

## 보안 주의사항

⚠️ **중요**: 민감한 정보가 포함된 파일은 절대 Git에 커밋하지 마세요!

`.gitignore`에 이미 포함되어 있지만, 확인하세요:
- `config/terraform-*.tfvars` (실제 파일)
- `config/terraform-*.env` (실제 파일)
- `terraform.tfvars`
- `*.tfvars`
- `terraform.tfstate`

**템플릿 파일은 커밋 가능:**
- `config/terraform-prod.tfvars.template` ✅
- `config/terraform-prod.env.template` ✅

**실제 파일은 커밋 금지:**
- `config/terraform-prod.tfvars` ❌
- `config/terraform-prod.env` ❌

민감한 정보는:
- 로컬: `config/terraform-prod.tfvars` (Git에 커밋 안 함)
- CI/CD: 환경변수 또는 Secrets Manager 사용

## 문제 해결

### ALB 서브넷 오류
ALB는 최소 2개의 서브넷이 필요합니다. 현재 Public Subnet을 2개로 분할하여 구성했습니다.

### 인증서 오류
- ACM 인증서는 Terraform이 자동으로 생성합니다
- DNS 검증이 완료되지 않으면 인증서가 "Issued" 상태가 되지 않습니다
- Route53 Name Servers를 도메인 등록업체에 등록했는지 확인하세요
- 검증 완료까지 몇 시간이 걸릴 수 있습니다

### 도메인 오류
Route53 Hosted Zone 생성 시 도메인이 유효하지 않으면 오류가 발생합니다.

