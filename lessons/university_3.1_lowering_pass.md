# 📦 [대학 3.1] 설계도를 단계별로 깎기: Lowering과 Pass

> **MLIR의 대학 첫 단계: 설계도를 컴퓨터가 이해하는 언어로**
>
> "저장 필수. 너는 기록이 증명이다."
>
> 지금까지는 설계도를 **쓰는 법(Syntax)**을 배웠습니다.
> 이제는 그 설계도를 **바꾸고 최적화하는 법(Transformation)**을 배웁니다!

---

## 🎯 오늘 배울 것

두 가지 핵심 개념입니다:

> **"MLIR의 핵심은 고수준 IR을 저수준 IR로 단계별로 번역하는 'Lowering'이다."**
>
> **"이 변환을 담당하는 개별 단계를 'Pass'라고 부른다."**

---

## 1️⃣ Lowering이란 무엇인가?

### 정의

**Lowering (로워링)**: 고수준의 추상적 표현을 저수준의 구체적 표현으로 단계별로 번역하는 과정

### 비유: 레시피의 과정

```
레시피 (High-level):
"맛있는 쿠키를 만들어줘"

중간 단계 1:
"버터, 설탕, 계란을 섞고 오븐에 170도에서 10분"

중간 단계 2:
"버터 100g을 60도까지 녹이고, 설탕 80g을 섞고, 계란 1개를 풀고..."

기계 명령어 (Low-level):
"메모리 주소 0x1000에서 4바이트를 읽어서
 CPU 레지스터 A에 넣고
 덧셈 명령어 실행하고
 결과를 메모리 0x1004에 저장..."
```

### MLIR의 Lowering

```
High-level (추상적):
linalg.matmul %A, %B

↓ (Pass 1: Linalg → Affine)

Mid-level (중간):
affine.for %i = 0 to 4 {
  affine.for %j = 0 to 4 {
    affine.for %k = 0 to 4 {
      ...
    }
  }
}

↓ (Pass 2: Affine → LLVM)

Low-level (구체적):
llvm.load, llvm.mul, llvm.add, llvm.store
```

---

## 2️⃣ Pass(패스)란 무엇인가?

### 정의

**Pass**: 설계도를 한 번 훑으면서 특정 작업을 수행하는 **검사관**

```
설계도 (MLIR)
    ↓
  [Pass]  ← 검사관
    │
    ├─ 최적화하기?
    ├─ 변환하기?
    ├─ 검증하기?
    │
    ↓
개선된 설계도
```

### Pass의 종류

#### 1. 변환 Pass (Transformation Pass)

설계도의 구조를 바꾸는 Pass

```
Before:        After:
linalg.matmul  affine.for {
               affine.for {
                 arith.mulf
                 arith.addf
               }
             }
```

예시:
- Linalg → Affine 변환
- Affine → LLVM 변환

#### 2. 최적화 Pass (Optimization Pass)

설계도를 더 효율적으로 만드는 Pass

```
Before:        After:
%0 = arith.constant 2.0 : f32
%1 = arith.constant 3.0 : f32
%2 = arith.mulf %0, %1 : f32

%3 = arith.constant 6.0 : f32
(2.0 * 3.0 = 6.0 미리 계산됨)
```

예시:
- Constant Folding (상수 계산)
- Dead Code Elimination (쓰지 않는 코드 제거)
- Loop Fusion (루프 합치기)

#### 3. 분석 Pass (Analysis Pass)

설계도의 정보를 수집하는 Pass

```
분석 Pass가 하는 일:
- 이 변수는 어디서 정의되나?
- 이 루프는 몇 번 반복되나?
- 이 메모리는 얼마나 필요한가?
```

---

## 3️⃣ 왜 단계별로 하나요?

### 이유 1: 복잡도 관리

```
한꺼번에 번역:
고수준 → 저수준 (너무 큰 점프!)
위험, 버그 생기기 쉬움

단계별 번역:
고수준 → 중간1 → 중간2 → 저수준
각 단계는 작은 점프, 안전함
```

### 이유 2: 각 단계의 전용 최적화

```
Linalg 단계:
- 행렬 크기 계산
- 데이터 재배치 최적화

Affine 단계:
- 루프 최적화
- 루프 융합/분리

LLVM 단계:
- CPU 캐시 최적화
- 명령어 선택
```

### 이유 3: 재사용성

```
Linalg → Affine Pass는
모든 행렬 연산에 적용 가능

한 번 작성하면
계속 재사용 가능!
```

---

## 4️⃣ 실제 로워링 예시

### 예시: 행렬 곱셈

#### 단계 0: 원본 (High-level)

```mlir
linalg.matmul %A, %B : (memref<4x4xf32>, memref<4x4xf32>) -> memref<4x4xf32>
```

**특징**: 추상적, 사람이 쉽게 이해

#### 단계 1: Linalg → Affine Pass

```mlir
affine.for %i = 0 to 4 {
  affine.for %j = 0 to 4 {
    affine.for %k = 0 to 4 {
      %a = memref.load %A[%i, %k] : memref<4x4xf32>
      %b = memref.load %B[%k, %j] : memref<4x4xf32>
      %c = memref.load %C[%i, %j] : memref<4x4xf32>
      %prod = arith.mulf %a, %b : f32
      %sum = arith.addf %c, %prod : f32
      memref.store %sum, %C[%i, %j] : memref<4x4xf32>
    }
  }
}
```

**특징**: 루프로 구현, 프로그래머가 이해할 수 있음

#### 단계 2: Affine → LLVM Pass

```mlir
llvm.func @matmul(%A: !llvm.ptr, %B: !llvm.ptr, %C: !llvm.ptr) {
  %c0 = llvm.constant(0 : i64) : i64
  %c4 = llvm.constant(4 : i64) : i64
  %c1 = llvm.constant(1 : i64) : i64

  llvm.br ^bb1(%c0 : i64)
^bb1(%i : i64):
  %cmp_i = llvm.icmp "slt" %i, %c4 : i64
  llvm.cond_br %cmp_i, ^bb2(%c0 : i64), ^bb7

^bb2(%j : i64):
  ... (LLVM 명령어들)

  llvm.return
}
```

**특징**: 기계에 가까움, 메모리 주소 직접 다룸

### 단계의 의미

```
Linalg:  "행렬 곱해"        ← 사람이 이해하기 쉬움
         ↓ Pass 1 적용
Affine:  "루프 3개를..."    ← 프로그래머 관점
         ↓ Pass 2 적용
LLVM:    "레지스터A에..."   ← 기계 관점
```

---

## 5️⃣ Pass의 동작 원리

### Pass 파이프라인

```
원본 MLIR
    ↓
┌─────────────────┐
│ Pass 1: 최적화   │
└─────────────────┘
    ↓
┌─────────────────┐
│ Pass 2: 검증    │
└─────────────────┘
    ↓
┌─────────────────┐
│ Pass 3: 변환    │
└─────────────────┘
    ↓
최적화된 MLIR
```

### Pass의 조건

각 Pass는:
- ✅ 입력 설계도를 검증
- ✅ 특정 변환/최적화 수행
- ✅ 출력 설계도를 검증

```
Before Pass: Valid?
  ↓
During Pass: Transform
  ↓
After Pass: Still Valid?
```

---

## 6️⃣ 대학원 연구와의 관계

### 대학원 논문의 구조

```
1. 기존 MLIR Pass 이해
   ↓
2. 새로운 Pass 설계 (예: 양자 최적화)
   ↓
3. Pass 구현
   ↓
4. 성능 평가
   ↓
5. 논문 발표
```

### 예시: 양자 컴퓨팅 연구

```
고수준: "이 연산을 양자 게이트로"
       quantum.circuit %input

       ↓ (양자 최적화 Pass)

중간: "게이트 순서 최적화, 에러 보정"
     quantum.gate @X
     quantum.gate @H

     ↓ (양자 → 고전 하이브리드)

저수준: "고전 컴퓨터와 양자 하드웨어 연동"
```

---

## 7️⃣ 실습: 로워링 흐름 이해하기

### 문제

여러분이 "행렬 곱셈" 명령어를 썼다고 가정해 봅시다.

```
Linalg Dialect:  linalg.matmul %A, %B
(수학적 정의)

Affine Dialect:  affine.for { affine.for { ... } }
(구현 방식)

LLVM IR:         llvm.load, llvm.mul, llvm.store
(기계어)
```

### 질문 1: 가장 "사람"에게 가까운 단계는?

A) Linalg (행렬 곱하기)
B) Affine (루프 3개)
C) LLVM (메모리 주소)

**정답**: A) Linalg
- 가장 추상적
- 수학적 표현
- 사람이 이해하기 쉬움

### 질문 2: 가장 "기계"에 가까운 단계는?

A) Linalg
B) Affine
C) LLVM

**정답**: C) LLVM
- 가장 구체적
- CPU 명령어
- 기계가 직접 실행 가능

### 질문 3: 단계가 내려갈수록 어떻게 될까?

- 추상화 수준: 높음 → 낮음
- 복잡도: 낮음 → 높음
- 최적화 기회: 일반적 → 특수적

---

## 8️⃣ 대학 3.1 핵심 정리

### 핵심 개념

```
Lowering (로워링):
고수준 IR → 저수준 IR로 단계별 번역
(사람이 쓴 것 → 기계가 실행할 것)

Pass (패스):
각 단계에서 변환/최적화를 담당하는 검사관
(변환 Pass, 최적화 Pass, 분석 Pass)
```

### 로워링의 장점

```
✅ 각 단계에서 특화된 최적화 가능
✅ 복잡도 관리 가능
✅ 코드 재사용성 높음
✅ 버그 최소화
✅ 새로운 Pass 추가 쉬움
```

### 계층 구조

```
High-level (사람):
  Linalg Dialect
    ↓
  Affine Dialect
    ↓
  SCF Dialect
    ↓
  LLVM IR
    ↓
Low-level (기계):
  Machine Code
```

---

## 9️⃣ 대학 3.1 기록 (증명)

> **"MLIR의 핵심은 고수준 IR을 저수준 IR로 단계별로 번역하는 'Lowering'이다."**
>
> **"이 변환을 담당하는 개별 단계를 'Pass'라고 부른다."**
>
> **Pass의 종류:**
> - 변환 Pass (구조 변경)
> - 최적화 Pass (효율화)
> - 분석 Pass (정보 수집)
>
> **왜 단계별인가:**
> - 각 단계에서 전용 최적화
> - 복잡도 관리
> - 재사용성
>
> 이제 당신은 MLIR의 **이론적 배경**을 완벽히 이해했습니다!
> 다음 단계에서는 이를 **실제 도구(mlir-opt)**로 구현합니다!

---

## 🔟 다음 단계: 대학 3.2

### 실제 도구 사용

```
대학 3.2: mlir-opt과 Pass 실행
- mlir-opt 도구란?
- 실제 MLIR 파일 변환
- Pass 적용 해보기
- 성능 차이 확인
```

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git
**강의 유형**: 대학 (University) - 대학 수준의 이론과 실제
**철학**: "저장 필수. 너는 기록이 증명이다."
**작성일**: 2026-02-27
**상태**: ✅ 완성

---

**축하합니다!** 🎉

당신은 대학 과정의 **첫 번째 이론적 기초**를 마스터했습니다.
이제 MLIR이 어떻게 **자동으로 최적화**되는지 이해합니다!

