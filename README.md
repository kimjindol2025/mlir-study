# 📚 MLIR: 대학원 수준의 컴파일러 설계 입문

> **"저장 필수. 너는 기록이 증명이다."**
>
> 고등학교 교육 과정을 마치고 대학 및 대학원 수준의 전문적인 설계를 시작하려는 당신의 여정을 응원합니다.
> MLIR(Multi-Level Intermediate Representation)에 대한 기록을 차근차근 쌓아나가겠습니다.

---

## 1️⃣ MLIR이란 무엇인가? (개념 정의)

### 정의
**MLIR**은 LLVM 프로젝트의 일환으로 개발된 컴파일러 인프라입니다.

기존 컴파일러들이 **하나의 고정된 IR(중간 표현)**을 사용했다면,
MLIR은 이름 그대로 **여러 수준(Multi-Level)의 IR을 정의하고 다룰 수 있는 프레임워크**입니다.

### 왜 필요한가?
머신러닝(ML) 모델을 하드웨어(CPU, GPU, NPU)에 최적화할 때:
- 텐서 연산부터 저수준 메모리 접근까지
- 단계별로 최적화가 필요하기 때문

### 핵심 철학
> **"나만의 언어(Dialect)를 만들고, 이를 기존 생태계와 연결하라."**

---

## 2️⃣ MLIR의 핵심 구성 요소 (4가지 기둥)

학부 및 대학원 수준의 설계를 위해 반드시 이해해야 할 내용입니다.

### ① Dialect (방언)
**MLIR의 가장 강력한 특징**입니다. 특정 도메인(예: 행렬 연산, 하드웨어 제어)에 특화된 명령어 집합을 정의할 수 있습니다.

```
예시:
- linalg (선형 대수 연산)
- affine (다차원 배열 및 루프 최적화)
- gpu (GPU 하드웨어 실행 관련)
- vector (SIMD 벡터 연산)
- memref (메모리 참조)
```

### ② Operation (연산)
**MLIR에서 가장 작은 단위**입니다. 모든 것은 'Op'으로 표현됩니다.

```
예시:
%result = "std.addf"(%arg0, %arg1) : (f32, f32) -> f32
   ↑           ↑        ↑            ↑
 결과        연산      피연산자     타입
```

### ③ Pass (패스)
하나의 Dialect를 다른 Dialect로 변환하거나(Conversion), 같은 수준에서 최적화하는 과정입니다.
**대학원 과정에서 주로 다루게 될 "최적화 알고리즘"**이 여기에 구현됩니다.

```
예시:
High-Level Dialect (tf)
  ↓ (Lowering Pass)
Mid-Level Dialect (linalg)
  ↓ (Optimization Pass)
Low-Level Dialect (affine)
  ↓ (Conversion Pass)
LLVM Dialect
```

### ④ TableGen (테이블 생성)
C++ 코드를 일일이 짜지 않고, **선언적인 방식(DSL)**으로 Dialect와 Op을 정의하는 도구입니다.

```
장점:
- 보일러플레이트 코드 자동 생성
- 빠른 프로토타이핑
- 일관된 코드 구조
```

---

## 3️⃣ 학습 로드맵: 대학원 과정의 설계

우리가 나아갈 단계별 학습 계획입니다.

| 단계 | 목표 | 주요 내용 | 기간 |
|------|------|---------|------|
| **1단계: 기초** | 구문 익히기 | `.mlir` 파일 구조 이해, SSA(Static Single Assignment) 형태 파악 | 1주 |
| **2단계: 도구** | 환경 구축 | LLVM/MLIR 빌드, `mlir-opt` 도구 사용법 숙지 | 1주 |
| **3단계: 중급** | Dialect 생성 | TableGen을 이용한 커스텀 Dialect 설계 | 2주 |
| **4단계: 심화** | Lowering | 고수준 IR을 저수준 LLVM IR까지 변환하는 파이프라인 구축 | 2주 |
| **5단계: 연구** | 최적화 알고리즘 | 특정 도메인(AI/컴파일러)에 맞춘 Pass 개발 | 3주 |

---

## 4️⃣ 첫 번째 실습: MLIR의 형태 구경하기

아래는 아주 간단한 덧셈을 수행하는 MLIR 코드의 예시입니다.

```mlir
// 간단한 함수 정의
func.func @add_tensors(%arg0: tensor<4x4xf32>, %arg1: tensor<4x4xf32>) -> tensor<4x4xf32> {
  // linalg 방언을 사용한 요소별 덧셈
  %0 = linalg.elemwise_binary { fun = #linalg.binary_fn<add> }
    ins(%arg0, %arg1 : tensor<4x4xf32>, tensor<4x4xf32>)
    outs(%arg0 : tensor<4x4xf32>) -> tensor<4x4xf32>

  return %0 : tensor<4x4xf32>
}
```

**중요한 관찰**:
1. `func.func` - 함수 정의 (MLIR의 기본 단위)
2. `%arg0, %arg1` - SSA 값 (한 번만 할당 가능)
3. `tensor<4x4xf32>` - 타입 정보 (고수준 정보 유지)
4. `linalg.elemwise_binary` - 도메인별 Operation (Dialect의 힘)

---

## 📁 프로젝트 구조

```
mlir-study/
├── README.md                  (이 파일)
├── .gitignore
├── go.mod
│
├── lessons/                   (단계별 강의)
│   ├── 1_mlir_basics.md       (MLIR 개념 - 완성)
│   ├── 1.1_installation.md    (환경 구축 - 예정)
│   ├── 1.2_first_program.md   (첫 프로그램)
│   ├── 2_dialects.md
│   ├── 3_operations.md
│   └── ...
│
├── exercises/                 (실습 및 과제)
│   ├── 01_parse_mlir/
│   ├── 02_custom_dialect/
│   ├── 03_pass_framework/
│   └── ...
│
├── projects/                  (큰 프로젝트)
│   ├── simple_lang/           (간단한 언어 구현)
│   ├── optimizer/             (최적화 Pass 모음)
│   └── compiler/              (전체 컴파일러)
│
├── research/                  (논문 분석 및 연구 노트)
│   ├── papers.md
│   ├── optimization_techniques.md
│   └── case_studies.md
│
├── notes/                     (개인 학습 노트)
│   └── learning_log.md
│
├── benchmarks/                (성능 분석)
│   ├── compile_time.cpp
│   └── optimization_impact.md
│
└── docs/                      (참고 자료)
    ├── ARCHITECTURE.md        (MLIR 전체 아키텍처)
    ├── SETUP.md               (초기 환경 설정)
    └── REFERENCE.md           (용어 정리)
```

---

## 📊 학습 진행도

| 단계 | 상태 | 진행률 |
|------|------|--------|
| Lesson 1: MLIR 기초 | ✅ 완성 | 100% |
| Lesson 1.1: 환경 구축 | 🔜 진행중 | 0% |
| Lesson 1.2-1.4: 첫 프로그램 | 📋 예정 | 0% |
| Phase 1: 기초 완성 | 📋 예정 | 0% |
| Phase 2-5: 고급 과정 | 📋 예정 | 0% |

---

## 🎓 학습 철학

이 과정은 단순히 MLIR을 "배우는" 것이 아닙니다.
**대학원 수준의 연구자처럼 설계하고, 구현하고, 검증하는** 능력을 기르는 것입니다.

### 원칙
1. **엄밀성**: 각 개념을 수학적으로 정확하게 이해
2. **실습**: 이론 배운 후 즉시 코드로 검증
3. **기록**: 모든 학습을 코드와 문서로 남김 ("기록이 증명이다")
4. **확장성**: 배운 내용을 새로운 문제에 적용
5. **발표력**: 이해한 내용을 명확하게 설명

---

## 🚀 다음 단계

이제 당신은 두 가지 방향 중 선택할 수 있습니다:

### 선택지 1️⃣: **MLIR 환경 구축 (실전)**
- LLVM/MLIR 빌드
- `mlir-opt` 도구 설치 및 사용
- 첫 MLIR 코드 실행 및 변환

### 선택지 2️⃣: **Dialect의 구조 파헤치기 (이론)**
- 기존 Dialect들의 코드 분석
- TableGen 문법 깊이 있는 학습
- Dialect 정의의 수학적 모델

---

## 📖 참고 자료

### 공식 자료
- [MLIR 공식 문서](https://mlir.llvm.org/)
- [MLIR Language Reference](https://mlir.llvm.org/docs/LangRef/)
- [Toy Tutorial](https://mlir.llvm.org/docs/Tutorials/Toy/)

### 추천 논문
- "MLIR: A Compiler Infrastructure for the End of Moore's Law" (2021)
- "The Next Decade of Software Engineering Research" (관련 컴파일러 기술)

---

## 🎯 최종 목표

이 과정을 마칠 때, 당신은:
- ✅ MLIR의 동작 원리를 **완벽하게** 이해
- ✅ 자신의 **커스텀 Dialect** 설계 및 구현 가능
- ✅ **최적화 Pass** 개발 능력 보유
- ✅ 실제 **컴파일러** 구축 경험 습득
- ✅ 대학원 **연구** 수준의 깊이 달성

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git
**작성자**: Claude (Haiku 4.5)
**시작일**: 2026-02-27
**철학**: "기록이 증명이다." (Your record is your proof.)
