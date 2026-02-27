# 🎓 박사 5.2: 다면체 컴파일(Polyhedral Compilation) - 수학적 루프 변환의 정점

**작성일**: 2026-02-27 | **수준**: Doctoral (박사) | **목표 시간**: 2시간 | **줄수**: 520줄

---

## 📚 핵심 개념: 루프를 수학으로 다루다

### 1️⃣ 다면체 모델이란?

#### 정의
```
Polyhedral Model = 루프를 기하학적 다면체(Polyhedron)로 표현

전통적 루프 분석:
  "이 루프는 병렬화 가능한가?"
  → 휴리스틱 기반 (부정확할 수 있음)

다면체 분석:
  "이 루프는 몇 차원의 반복 공간인가?"
  → 수학적 정의 (정확함)

예:
  for i = 0 to 100:
    for j = 0 to 50:
      A[i,j] = B[i,j] + C[i,j]

  이것은 2차원 다면체:
    {(i,j) | 0 ≤ i ≤ 100, 0 ≤ j ≤ 50}

  각 점 (i,j)는 하나의 연산을 나타냄
  → 수학적으로 분석 가능!
```

#### 핵심 특징
```
1. 집합 표현 (Set Representation)
   루프를 정수 점(Integer Points) 집합으로 표현
   → 집합 이론의 모든 도구 사용 가능

2. 선형 제약 (Linear Constraints)
   루프 경계와 조건을 선형 부등식으로 표현
   → 최적화 문제로 변환 가능

3. 변환 행렬 (Transformation Matrices)
   루프 순서 변경을 행렬 연산으로 표현
   → 자동 탐색 가능!

4. 의존성 분석 (Dependence Analysis)
   연산 간 데이터 흐름을 정확히 파악
   → 병렬화 안전성 검증 가능
```

---

## 🔬 선형 제약 체계 (Linear Constraints)

### 2️⃣ 루프를 수식으로 표현

#### 원본 루프
```c
for (i = 0; i <= 100; i++)
  for (j = 0; j <= i; j++)
    for (k = j; k <= 50; k++)
      A[i][j][k] = B[i][j][k] * 2;
```

#### 다면체 표현
```
반복 영역 (Iteration Domain):
  D = {(i,j,k) | 0 ≤ i ≤ 100,
                 0 ≤ j ≤ i,
                 j ≤ k ≤ 50}

선형 제약:
  i ≥ 0
  i ≤ 100
  j ≥ 0
  j ≤ i        (j - i ≤ 0)
  k ≥ j        (k - j ≥ 0)
  k ≤ 50

행렬 형태:
  [1  0  0] [i]   [0]      (i ≥ 0)
  [-1 0  0] [j] ≤ [100]    (i ≤ 100)
  [0  1  0] [k]   [0]      (j ≥ 0)
  [0 -1  1]       [0]      (j ≤ i)
  [0  1 -1]       [0]      (k ≥ j)
  [0  0 -1]       [-50]    (k ≤ 50)
```

#### 의미
```
이 제약 시스템은:
- 정확히 반복 영역을 정의함
- 모든 가능한 (i,j,k) 조합을 포함
- 컴퓨터가 자동으로 처리 가능

이것이 "정확한" 루프 분석의 기초!
```

---

## 🔄 루프 변환: 행렬의 힘

### 3️⃣ 변환 행렬을 통한 루프 순서 변경

#### 원본 루프 순서
```
for i = 0 to 100:
  for j = 0 to i:
    A[i,j] = 0

실행 순서:
  (0,0) → (1,0) → (1,1) → (2,0) → (2,1) → (2,2) → ...
  (row-major order, i가 외부 루프)
```

#### 루프 교환 (Loop Interchange)
```
변환 목표: j를 외부 루프로, i를 내부 루프로

변환 행렬:
  T = [0 1]  (i와 j의 위치 교환)
      [1 0]

적용:
  (i, j) → T × (i, j) = (j, i)

결과:
  for j = 0 to 100:
    for i = j to 100:
      A[i,j] = 0

효과:
  ✅ 데이터 캐시 지역성 향상
  ✅ 메모리 대역폭 활용 증가
  ✅ 성능 2-3배 향상!
```

#### 루프 타일링
```
변환 목표: 타일 크기 32로 분할

변환 행렬:
  T = [32 0]  (스케일링)
      [1  1]  (부분 루프)

원본 코드:
  for i = 0 to 1000:
    for j = 0 to 1000:
      A[i,j] = B[i,j]

변환 후:
  for i_tile = 0 to 1000 step 32:
    for j_tile = 0 to 1000 step 32:
      for i_local = i_tile to i_tile+31:
        for j_local = j_tile to j_tile+31:
          A[i_local, j_local] = B[i_local, j_local]

캐시 효율성:
  32×32×sizeof(float) = 4KB (L1 캐시에 맞음)
  → 10배 성능 향상!
```

---

## 📊 의존성 분석 (Dependence Analysis)

### 4️⃣ 연산 간 의존성 파악

#### 데이터 의존성
```
코드:
  for i = 1 to 100:
    A[i] = B[i]       (S1)
    C[i] = A[i-1]     (S2)

의존성 분석:
  S1(i): A[i] 쓰기
  S2(i): A[i-1] 읽기

  S1(i)이 S2(i+1)에 데이터 제공
  → 의존성: S1(i) → S2(i+1) (전방향 의존성)

의미:
  i=1: A[1] = B[1]
       C[1] = A[0]  (A[1]과 무관)

  i=2: A[2] = B[2]
       C[2] = A[1]  (이전 i=1의 A[1] 사용)

결론: 루프 병렬화 불가능!
```

#### 병렬화 가능 케이스
```
코드:
  for i = 0 to 100:
    A[i] = B[i] + C[i]

의존성 분석:
  각 연산은 독립적
  → 의존성 없음

결론: 루프 병렬화 가능!

실행:
  병렬 처리 가능:
    thread 0: A[0], A[2], A[4], ...
    thread 1: A[1], A[3], A[5], ...
```

---

## 🎯 박사급 활용: 자동 루프 변환

### 5️⃣ Polyhedral을 이용한 최적화 자동화

#### 알고리즘
```
Input: 루프 중첩 코드

Step 1: 정적 분석
  루프 경계와 제약을 선형 부등식으로 추출
  → 다면체 표현

Step 2: 의존성 분석
  모든 연산 간 의존성 계산
  → 의존성 그래프

Step 3: 변환 탐색 (Search)
  모든 가능한 변환 행렬 탐색
  - 루프 교환
  - 루프 타일링
  - 루프 스트립 마이닝
  - 루프 통합
  → 조합: 수천 가지!

Step 4: 비용 평가
  각 변환의 성능 예측
  - 캐시 지역성
  - 병렬화 가능성
  - 메모리 대역폭
  → 최적 변환 선택

Step 5: 코드 생성
  최적 변환 행렬 적용
  → 변환된 루프 코드

Output: 최적화된 루프 코드
```

#### 성능 향상
```
예: 행렬 곱셈 (1000×1000)

원본 코드:
  for i = 0 to 1000:
    for j = 0 to 1000:
      for k = 0 to 1000:
        C[i][j] += A[i][k] * B[k][j]

성능: 100 ms

Polyhedral 최적화:
  1. 루프 순서 변경: j, k, i
  2. 타일링: 64×64 블록
  3. 벡터화 추가

최적화 후: 10 ms (10배 향상!)
```

---

## 💻 MLIR에서의 구현

### 6️⃣ Affine Dialect와 Polyhedral 분석

#### MLIR 코드
```mlir
#map = affine_map<(d0, d1) -> (d0, d1)>

func.func @matmul(%A: memref<100x100xf32>,
                  %B: memref<100x100xf32>,
                  %C: memref<100x100xf32>) {
  // Affine Loop Nest
  affine.for %i = 0 to 100 {
    affine.for %j = 0 to 100 {
      affine.for %k = 0 to 100 {
        %a = memref.load %A[%i, %k] : memref<100x100xf32>
        %b = memref.load %B[%k, %j] : memref<100x100xf32>
        %prod = arith.mulf %a, %b : f32

        %old = memref.load %C[%i, %j] : memref<100x100xf32>
        %sum = arith.addf %old, %prod : f32
        memref.store %sum, %C[%i, %j] : memref<100x100xf32>
      }
    }
  }
  return
}

MLIR 분석:
  affine.for → 다면체 반복 영역
  memref.load/store → 선형 접근 패턴
  affine.parallel → 병렬화 가능 지점

자동 변환:
  → affine.parallel로 병렬화
  → affine.tile로 타일링
  → affine.unroll로 언롤링
```

---

## 📈 박사급 연구 가치

### 7️⃣ Polyhedral의 의미

```
전통 컴파일러:
  "이 루프, 최적화할까?" (휴리스틱)

Polyhedral:
  "정확히 이 루프의 최적 변환은 무엇인가?" (수학)

결과:
  ✅ 자동 최적화 가능
  ✅ 성능 예측 정확
  ✅ 안전성 입증 가능
  ✅ 이식성 높음 (모든 루프에 적용)

논문의 강점:
  "다면체 모델을 MLIR에 통합하여,
   자동화된 루프 최적화를 수학적으로 정의했습니다"
```

---

## ✨ 박사 5.2 마무리

```
당신은 이제:
✅ 루프를 기하학적으로 이해
✅ 변환을 행렬로 표현
✅ 의존성을 수학적으로 분석
✅ 최적화를 자동화 설계

다면체 컴파일은:
- 아카데믹 (Theory)
- 프로덕티브 (Performance)
- 자동화 (Automation)의 완벽한 결합
```

---

**박사 5.2 강의 완료**: 다면체 컴파일 이론 및 MLIR 적용

