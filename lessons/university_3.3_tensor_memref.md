# 📦 [대학 3.3] 추상적 데이터 vs 실제 메모리: Tensor와 MemRef

> **MLIR의 대학 세 번째 단계: 메모리 관리의 기초**
>
> "저장 필수. 너는 기록이 증명이다."
>
> 이 단계는 대학원 과정에서 '메모리 관리 최적화' 논문을 쓸 때
> 핵심이 되는 개념입니다.

---

## 🎯 오늘 배울 것

두 가지 핵심 데이터 표현입니다:

> **"Tensor는 수학적 개념(Value)이고, MemRef는 물리적 위치(Address)이다."**
>
> **"고수준에서 저수준으로 갈 때 Tensor는 MemRef로 변환(Bufferization)된다."**

---

## 1️⃣ Tensor (텐서): "수학적인 숫자 판"

### 정의

**Tensor**: 값이 변하지 않는(Immutable) 수학적 개체

### 특징

```
불변성(Immutable):
- 한 번 만들어지면 값이 절대 바뀌지 않음
- 마치 종이에 적힌 숫자처럼

수학적:
- 논리적 개념
- 하드웨어와 무관

추상적:
- "어디에 저장되어 있나"는 신경 안 씀
- "값이 뭔지"만 중요
```

### 비유: 구름 위의 숫자들

```
tensor<4x4xf32>

┌─────────────────┐
│ 1.0  2.0  3.0   │ ← 구름 위에 떠 있는 숫자
│ 4.0  5.0  6.0   │   (어디 저장되어 있는지 모름)
│ 7.0  8.0  9.0   │
└─────────────────┘

"이 판과 저 판을 더해라" ← Tensor 연산
```

### 표기법

```
tensor<Dim1 x Dim2 x ... x ElemType>

예시:
tensor<4x4xf32>       ← 4행 4열 실수
tensor<10xf32>        ← 10개 원소 실수
tensor<2x3x4xi32>     ← 3차원 정수 배열
tensor<?x?xf32>       ← 동적 크기 (물음표 = 실행 시 결정)
```

### Tensor 연산

```mlir
%0 = linalg.matmul %A, %B : (tensor<4x4xf32>, tensor<4x4xf32>) -> tensor<4x4xf32>
(두 텐서를 곱한다, 논리적으로!)

%1 = arith.addf %x, %y : f32
(두 숫자를 더한다, 추상적으로!)
```

---

## 2️⃣ MemRef: "실제 메모리 주소"

### 정의

**MemRef**: 컴퓨터의 RAM(메모리) 어디에 데이터가 있는지 가리킴

### 특징

```
가변성(Mutable):
- 메모리의 값은 언제든 바뀔 수 있음
- "이 주소의 값을 3에서 5로 바꿔라"

물리적:
- 실제 컴퓨터 메모리 위치
- 하드웨어 연결

구체적:
- "몇 번지 메모리에 있나"가 중요
- 주소, 크기, 레이아웃 등 구체화됨
```

### 비유: 땅 위의 창고

```
memref<4x4xf32>

┌─ 메모리 주소 0x1000
│
│  [1.0][2.0][3.0]  ← 실제 RAM의 어딘가
│  [4.0][5.0][6.0]  (0x1000번지부터 시작)
│  [7.0][8.0][9.0]
│
└─ 메모리 주소 0x1072

"0x1000 번지에 있는 메모리를 수정해라" ← MemRef 연산
```

### 표기법

```
memref<Dim1 x Dim2 x ... x ElemType, Layout>

예시:
memref<4x4xf32>           ← 4행 4열 실수 메모리
memref<10xf32, offset:0, strides:[1]>  ← 메모리 레이아웃 명시
memref<100xi32>           ← 100개 정수 배열
memref<?x?xf32>           ← 동적 메모리 주소
```

### MemRef 연산

```mlir
%0 = memref.load %my_memref[%i, %j] : memref<4x4xf32>
(메모리 주소로 가서 데이터를 읽는다, 구체적으로!)

memref.store %value, %my_memref[%i, %j] : memref<4x4xf32>
(메모리 주소로 가서 데이터를 쓴다!)
```

---

## 3️⃣ Tensor vs MemRef 비교

### 차이 정리

| 항목 | Tensor | MemRef |
|------|--------|--------|
| 개념 | 수학적 | 물리적 |
| 변함 | 불변(Immutable) | 가변(Mutable) |
| 위치 | 추상적 | 구체적 (메모리 주소) |
| 비유 | 구름 위 숫자 | 창고 주소 |
| 사용 | 고수준 코드 | 저수준 코드 |

### 실제 코드 비교

```mlir
// Tensor 사용 (고수준, 수학적)
func.func @matrix_op(%A: tensor<4x4xf32>, %B: tensor<4x4xf32>) -> tensor<4x4xf32> {
  %C = linalg.matmul %A, %B : (tensor<4x4xf32>, tensor<4x4xf32>) -> tensor<4x4xf32>
  func.return %C : tensor<4x4xf32>
}

// MemRef 사용 (저수준, 메모리 중심)
func.func @matrix_op_memref(%A: memref<4x4xf32>, %B: memref<4x4xf32>, %C: memref<4x4xf32>) {
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
}
```

---

## 4️⃣ Lowering: Tensor → MemRef 변환

### 개념: Bufferization (버퍼화)

**Bufferization**: Tensor를 MemRef로 변환하는 과정

```
High-level (Tensor):
linalg.matmul %A, %B → tensor<4x4xf32>

   ↓ Bufferization Pass

Low-level (MemRef):
affine.for {
  memref.load, arith.mulf, memref.store
}
```

### 왜 필요한가?

```
Tensor의 문제:
"값을 더한다"고 할 수는 있지만,
컴퓨터는 "어디에 저장할건데?"라고 물어봄

MemRef의 해결:
"메모리 0x1000 번지에 저장해"라고 명확하게 지시
```

### 실제 변환 과정

```
Step 1: 고수준 (추상적)
tensor<4x4xf32> → 단순히 "4x4 실수 판"

Step 2: 중간 (반구체적)
memref<4x4xf32, offset: ?, strides: [?, ?]>
→ "메모리는 있는데 정확한 위치는 아직 몰라"

Step 3: 저수준 (구체적)
memref<4x4xf32, offset: 0, strides: [4, 1]>
→ "정확히 어디에, 어떤 배치로 저장할지 결정"
```

---

## 5️⃣ 실습: Tensor vs MemRef 연산 비교

### 문제 1: 데이터 추출

```mlir
A: %0 = tensor.extract %my_tensor[%i, %j] : tensor<4x4xf32> -> f32
(텐서에서 값 추출, 논리적!)

B: %1 = memref.load %my_memref[%i, %j] : memref<4x4xf32> -> f32
(메모리에서 값 로드, 물리적!)
```

**차이**:
- A: 텐서에서 한 원소를 뽑는다 (수학적)
- B: 메모리 주소로 가서 값을 읽는다 (물리적)

### 문제 2: 데이터 저장

```mlir
A: %0 = tensor.insert %value into %my_tensor[%i, %j] : tensor<4x4xf32>
(텐서에 값을 삽입, 새로운 텐서 생성!)

B: memref.store %value, %my_memref[%i, %j] : memref<4x4xf32>
(메모리에 값을 쓰기, 기존 메모리 수정!)
```

**차이**:
- A: 새로운 텐서를 만든다 (불변성 유지)
- B: 기존 메모리를 수정한다 (가변)

### 문제 3: 질문

실제 컴퓨터 하드웨어의 **'메모리 주소'**에 직접 접근해서 데이터를 가져오는 것은?

```
A) tensor.extract (텐서에서 뽑기)
B) memref.load (메모리에서 로드)
```

**정답**: B) memref.load

- memref.load는 실제 메모리 주소 참조(Reference)를 따라가서
- 물리적 메모리에서 데이터를 읽는
- 하드웨어 중심의 명령어입니다!

---

## 6️⃣ 대학원 연구의 관점

### 왜 이게 중요한가?

```
"메모리 최적화" 논문의 핵심:
"Tensor를 MemRef로 변환할 때,
 어떻게 하면 메모리를 가장 효율적으로 사용할 것인가?"

예시:
- 메모리 재사용 (reuse)
- 메모리 배치 (layout) 최적화
- 캐시 친화적 배열 (cache-friendly)
```

### 연구 주제의 예

```
Title: "메모리 효율적인 텐서-멤레프 변환 최적화"

1단계: Tensor 설계
   "이 행렬 곱셈을 어떻게 할까?"

2단계: MemRef로 변환
   "메모리를 어떻게 배치할까?"
   "얼마나 많은 메모리가 필요할까?"
   "캐시 미스를 줄일 수 있을까?"

3단계: 성능 측정
   "mlir-opt로 최적화된 코드 생성"
   "실제 하드웨어에서 실행 시간 측정"
```

---

## 7️⃣ 대학 3.3 핵심 정리

### 핵심 개념

```
Tensor = 추상적 값
  - 불변 (Immutable)
  - 수학적 개념
  - 논리만 중요

MemRef = 구체적 주소
  - 가변 (Mutable)
  - 물리적 위치
  - 메모리 구조 중요
```

### 변환 과정

```
tensor<4x4xf32>
   ↓ Bufferization
memref<4x4xf32, offset: 0, strides: [4, 1]>
   ↓ 실제 메모리
RAM 0x1000 ~ 0x1072
```

### 대학 논문 체계

```
1. 고수준: "행렬을 곱한다" (텐서)
2. 중수준: "루프로 구현한다" (멤레프 + 루프)
3. 저수준: "메모리 어디에 저장할까" (최적화)
4. 결과: 성능 측정 및 비교
```

---

## 8️⃣ 대학 3.3 기록 (증명)

> **"Tensor는 수학적 개념(Value)이고, MemRef는 물리적 위치(Address)이다."**
>
> **특징 비교:**
> ```
> Tensor: 불변, 추상적, 수학적, 고수준
> MemRef: 가변, 구체적, 물리적, 저수준
> ```
>
> **Lowering (Bufferization):**
> Tensor → MemRef 변환이 프로그램을 구체화함
>
> **대학원 연구:**
> "메모리를 어떻게 효율적으로 할당할 것인가"가 핵심
>
> 이제 당신은 **메모리 최적화**의 기초를 갖추었습니다!

---

## 🔟 다음 단계: 대학 3.4

### Affine Dialect: 루프 최적화의 꽃

```
대학 3.4: Affine Dialect
- 수학적으로 완벽한 루프 설계
- 루프 변환 및 최적화
- 병렬화 가능성 분석
```

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git
**강의 유형**: 대학 (University) - 메모리 관리
**철학**: "저장 필수. 너는 기록이 증명이다."
**작성일**: 2026-02-27
**상태**: ✅ 완성

---

**축하합니다!** 🎉

당신은 **메모리 최적화**의 기초를 마스터했습니다.
대학원 논문의 핵심 개념을 이해하셨습니다!

