# 📦 [대학 3.4] 수학적으로 완벽한 루프: Affine Dialect

> **MLIR의 대학 네 번째 단계: 루프 최적화의 정수**
>
> "저장 필수. 너는 기록이 증명이다."
>
> 대학원 과정에서 하드웨어 가속기 설계의 핵심인
> **'틸링'과 '벡터화'의 근간**이 됩니다.

---

## 🎯 오늘 배울 것

한 가지 핵심 개념입니다:

> **"Affine은 루프와 메모리 접근을 수학적 수식으로 정의하여 최적화한다."**
>
> **"이를 통해 병렬화, 틸링 등 고차원적 하드웨어 최적화가 가능해진다."**

---

## 1️⃣ Affine 루프란?

### 정의

**Affine Loop**: 루프의 범위와 메모리 접근 주소가 **선형 수식(Linear Equation)**으로 표현되는 루프

### 핵심 특징

```
범위가 명확함:
- "0부터 10까지" (상수로 정해짐)
- "크기 N인 배열의 전체" (변수지만 고정)

메모리 접근이 예측 가능:
- %buffer[%i] ← 선형
- %buffer[%i * 2 + 1] ← 선형
- %buffer[%i * %j] ← 비선형 (X, Affine 아님)

컴파일러가 미리 알 수 있음:
- 몇 번 반복할 것인가
- 어느 메모리를 접근할 것인가
→ 미리 최적화 가능!
```

### Affine vs Non-Affine

```
✅ Affine (최적화 가능):
- affine.for %i = 0 to 10
- %val = affine.load %buf[%i]
- %val = affine.load %buf[%i * 2 + 1]

❌ Non-Affine (최적화 어려움):
- scf.for (실행 시 결정되는 범위)
- %val = memref.load %buf[%i * %j] (비선형)
- %val = memref.load %buf[compute_index(%i)] (함수 호출)
```

---

## 2️⃣ 왜 Affine이 강력한가?

### 장점 1: 미리 계산 가능

```
General Loop:
for (int i = 0; i < user_input; i++)  ← 실행해야 알 수 있음
  ...

Affine Loop:
affine.for %i = 0 to 100  ← 컴파일 시 "100번 돈다"를 알 수 있음
  ...
```

### 장점 2: 병렬화 가능성 분석

```
Affine을 쓰면:
for i = 0 to 100
  for j = 0 to 100
    C[i,j] = A[i,j] + B[i,j]

컴퓨터: "아! i와 j가 겹치지 않으니
       모든 (i,j) 쌍을 동시에 처리해도 돼!"
       → 병렬화 자동으로 가능!

Non-Affine을 쓰면:
for i = 0 to user_input
  ...
컴퓨터: "몰라... 겹치는지 안 겹치는지 실행해봐야 알겠는데..."
```

### 장점 3: 메모리 접근 패턴 최적화

```
Affine.load %buf[%i, %j * 2]

컴퓨터: "아! 이 루프는 캐시 라인을 이렇게 건드리는구나.
       그럼 메모리를 미리 이렇게 배치해놓으면 최적이겠다!"
       → 틸링, 벡터화 등 고급 최적화 가능!
```

---

## 3️⃣ Affine 문법

### 기본 형식

```mlir
affine.for %i = 범위 to 범위 {
  // 루프 본체
  %val = affine.load %buffer[선형식] : memref<...>
  affine.store %val, %buffer[선형식] : memref<...>
}
```

### 예제 1: 단순 1D 루프

```mlir
affine.for %i = 0 to 10 {
  %val = affine.load %buffer[%i] : memref<10xf32>
  %new_val = arith.addf %val, 1.0 : f32
  affine.store %new_val, %buffer[%i] : memref<10xf32>
}
```

**의미**: 0부터 9까지 버퍼의 각 원소에 1.0을 더함

### 예제 2: 중첩 루프

```mlir
affine.for %i = 0 to 4 {
  affine.for %j = 0 to 4 {
    %a = affine.load %A[%i, %j] : memref<4x4xf32>
    %b = affine.load %B[%i, %j] : memref<4x4xf32>
    %sum = arith.addf %a, %b : f32
    affine.store %sum, %C[%i, %j] : memref<4x4xf32>
  }
}
```

**의미**: 4x4 행렬 두 개를 더해서 결과를 저장

### 예제 3: 선형 주소 계산

```mlir
affine.for %i = 0 to 10 {
  // 주소: i * 2 + 1 (선형식)
  %val = affine.load %buffer[%i * 2 + 1] : memref<21xf32>

  // 계산...

  %offset = affine.apply affine_map<(d0) -> (d0 * 3)> (%i)
  affine.store %val, %buffer[%offset] : memref<30xf32>
}
```

**의미**: 선형 수식으로 메모리 주소를 계산하며 접근

---

## 4️⃣ Affine의 강점: 최적화 기법

### 기법 1: 병렬화 (Parallelization)

```
원본:
affine.for %i = 0 to 100
  affine.for %j = 0 to 100
    C[i,j] = A[i,j] + B[i,j]

Affine 분석:
"아! i와 j가 독립적이네.
 모든 (i,j) 쌍을 동시에 처리 가능하다!"

병렬화 후:
parallel for (i, j) in 0:100 x 0:100  ← GPU/멀티코어 병렬화!
  C[i,j] = A[i,j] + B[i,j]
```

### 기법 2: 틸링 (Tiling)

```
원본:
for i = 0 to 1000
  for j = 0 to 1000
    C[i,j] = A[i,j] + B[i,j]

문제: 100만 번 메모리 접근 (캐시 효율 낮음)

틸링 후:
for ti = 0 to 1000 by 32
  for tj = 0 to 1000 by 32
    for i = ti to min(ti+32, 1000)
      for j = tj to min(tj+32, 1000)
        C[i,j] = A[i,j] + B[i,j]

효과: 32x32 타일씩 처리 → 캐시 효율 ↑↑↑
```

### 기법 3: 벡터화 (Vectorization)

```
원본:
for i = 0 to 1000
  C[i] = A[i] + B[i]

벡터화 후:
for i = 0 to 1000 by 4  ← 4개씩
  C[i:i+4] = A[i:i+4] + B[i:i+4]  ← 벡터 연산 (SIMD)

효과: 1000번 → 250번 반복, 속도 4배 향상!
```

---

## 5️⃣ 실습: Affine이 좋아하는 상황

### 문제 1

다음 중 Affine이 최적화하기 좋은 상황은?

```
A) 사용자가 키보드로 입력한 숫자만큼 반복하는 루프
   for (int i = 0; i < user_input; i++)

B) 이미 크기가 정해진 100x100 행렬을 처음부터 끝까지 훑는 루프
   affine.for %i = 0 to 100
     affine.for %j = 0 to 100
```

**정답**: B) 정해진 크기의 루프

**이유**:
- A: 실행 시점에 결정되는 범위 → 컴파일 시 최적화 불가
- B: 컴파일 시 범위가 명확 → 미리 최적화 가능

### 문제 2

다음 중 Affine 메모리 접근은?

```
A) affine.load %buf[%i * %j]  ← 비선형
B) affine.load %buf[%i * 2 + %j]  ← 선형
C) affine.load %buf[compute_index(%i)]  ← 함수 호출
```

**정답**: B) affine.load %buf[%i * 2 + %j]

**이유**:
- A: 두 변수의 곱 = 비선형 (X)
- B: 선형 조합 = 선형 (O)
- C: 함수 호출 = 예측 불가 (X)

---

## 6️⃣ 대학원 연구: Affine의 역할

### 고성능 컴퓨팅(HPC) 연구 주제

```
Title: "Affine 루프 최적화를 통한 GPU 성능 향상"

1. Affine 루프 분석
   "이 루프가 병렬화 가능한가?"
   "메모리 접근 패턴이 뭔가?"

2. 최적화 기법 적용
   "틸링으로 캐시 효율 개선"
   "벡터화로 처리량 증가"
   "병렬화로 멀티코어 활용"

3. 성능 측정
   "원본 대비 몇 배 빨라졌는가?"
   "에너지 효율은?"

4. 논문 발표
   "우리의 Affine 최적화 기법으로 10배 성능 향상!"
```

### 실제 예시

```
NVIDIA GPU 설계에서:
"이 행렬 연산은 Affine 루프다.
 따라서 우리는 CUDA 커널로 병렬화 가능하다!"

Google TPU 설계에서:
"이 Deep Learning 루프는 Affine이다.
 따라서 타일링과 벡터화로 대역폭 효율을 80% 향상시킬 수 있다!"
```

---

## 7️⃣ 대학 3.4 핵심 정리

### Affine의 정의

```
범위: 선형 범위 (0 to 10)
메모리: 선형 주소 (i * 2 + 1)

→ 컴파일 시 미리 계산 가능
→ 최적화 극대화
```

### 최적화 기법

```
병렬화: 독립적인 루프 반복 동시 실행
틸링: 메모리 캐시 효율 향상
벡터화: 벡터 연산으로 처리 속도 증가
```

### 중요성

```
❌ Non-Affine:
"실행해봐야 알겠는데..."
→ 제한된 최적화

✅ Affine:
"설계 단계에서 다 계산해!
 최적 전략을 미리 짜놓을 수 있어!"
→ 극대화된 최적화
```

---

## 8️⃣ 대학 3.4 기록 (증명)

> **"Affine은 루프와 메모리 접근을 수학적 수식으로 정의하여 최적화한다."**
>
> **"이를 통해 병렬화, 틸링 등 고차원적 하드웨어 최적화가 가능해진다."**
>
> **Affine의 조건:**
> - 범위가 선형 (상수 또는 선형식)
> - 메모리 접근이 선형식
> - 예측 가능성 극대화
>
> **최적화 기법:**
> - 병렬화 (Parallelization)
> - 틸링 (Tiling)
> - 벡터화 (Vectorization)
>
> 이제 당신은 **고성능 컴퓨팅의 기초**를 갖추었습니다!

---

## 🔟 다음 단계: 대학 3.5 (최종)

### MLIR → LLVM IR → 실행

```
대학 3.5: 최종 코드 생성과 실행
- MLIR을 LLVM IR로 변환
- 컴파일러 백엔드
- 실제 바이너리 생성
- 성능 측정

설계도가 현실의 기계어로!
```

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git
**강의 유형**: 대학 (University) - 고성능 컴퓨팅
**철학**: "저장 필수. 너는 기록이 증명이다."
**작성일**: 2026-02-27
**상태**: ✅ 완성

---

**축하합니다!** 🎉

당신은 **루프 최적화의 정수**를 마스터했습니다.
이제 고성능 컴퓨팅 연구의 핵심을 이해합니다!

