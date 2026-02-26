# 📦 [대학 3.2] 실제 도구 다루기: mlir-opt

> **MLIR의 대학 두 번째 단계: 컴파일러의 돋보기**
>
> "저장 필수. 너는 기록이 증명이다."
>
> 이제 우리는 머릿속 설계도를 넘어,
> 컴퓨터가 실제로 이 설계도를 어떻게 요리하는지 관찰하는 도구를 배웁니다!

---

## 🎯 오늘 배울 것

한 가지 핵심 도구입니다:

> **"mlir-opt는 설계도를 분석하고 변환하는 핵심 도구이다."**
>
> **"--pass-이름 옵션을 통해 최적화나 로워링을 수행한다."**

---

## 1️⃣ mlir-opt란 무엇인가?

### 정의

**mlir-opt**: MLIR Optimizer의 약자
- 설계도(.mlir 파일)를 입력받아
- 우리가 명령한 패스(Pass)를 실행한 후
- 변환된 결과물을 다시 출력해주는 프로그램

### 비유: 음식 조리 과정

```
원본 식재료 (.mlir 파일)
    ↓
[mlir-opt --pass-이름] ← 조리 방법 지정
    ↓
조리된 요리 (변환된 .mlir 파일)
```

### 역할

```
mlir-opt는 "컴파일러의 돋보기"
- 내 코드가 최적화되었는가?
- 저수준으로 잘 변환되었는가?
- 메모리는 효율적으로 사용하는가?
→ 모두 확인 가능!
```

---

## 2️⃣ 명령어 구조

### 기본 형식

```bash
mlir-opt 입력파일.mlir --pass-이름
```

### 예시들

```bash
# 1. Canonicalize Pass (표준화)
mlir-opt my_code.mlir --canonicalize

# 2. Linalg to Loops 변환
mlir-opt my_code.mlir --convert-linalg-to-loops

# 3. 여러 Pass 연쇄 실행
mlir-opt my_code.mlir --canonicalize --convert-linalg-to-loops

# 4. 결과를 파일로 저장
mlir-opt my_code.mlir --canonicalize -o optimized.mlir
```

### 옵션 설명

```
mlir-opt           : 실행 프로그램
my_code.mlir       : 입력 파일 (원본 설계도)
--pass-이름        : 적용할 패스
-o output.mlir     : 출력 파일 (변환된 설계도)
```

---

## 3️⃣ 대표적인 Pass들

### Pass 1: Canonicalize (표준화)

**역할**: "청소부" 같은 패스

```
특징:
- 뻔한 계산을 미리 해버림
- 쓸모없는 코드를 정리
- 코드를 정규화 (표준 형태로)
```

**예시 1: 상수 폴딩**

```
[Before]
%0 = arith.constant 1 : i32
%1 = arith.constant 2 : i32
%2 = arith.addi %0, %1 : i32

[After --canonicalize]
%0 = arith.constant 3 : i32
(1 + 2를 미리 계산!)
```

**예시 2: 불필요한 코드 제거**

```
[Before]
%0 = arith.addi %a, 0 : i32  // 0을 더하는 건 의미 없음
%1 = arith.muli %0, 1 : i32  // 1을 곱하는 것도 의미 없음

[After --canonicalize]
// 두 줄이 모두 제거됨!
// %a만 남음
```

### Pass 2: Convert-Linalg-to-Loops (변환)

**역할**: "조각가" 같은 패스

```
특징:
- 고수준 명령을 중수준으로 변환
- 선형대수 연산을 루프로 구체화
- 로워링의 일부
```

**예시**

```
[Before]
linalg.matmul %A, %B : (memref<4x4xf32>, memref<4x4xf32>) -> memref<4x4xf32>

[After --convert-linalg-to-loops]
affine.for %i = 0 to 4 {
  affine.for %j = 0 to 4 {
    affine.for %k = 0 to 4 {
      %a = memref.load %A[%i, %k]
      %b = memref.load %B[%k, %j]
      %c = memref.load %C[%i, %j]
      %prod = arith.mulf %a, %b : f32
      %sum = arith.addf %c, %prod : f32
      memref.store %sum, %C[%i, %j]
    }
  }
}
```

---

## 4️⃣ 최적화의 실제 효과

### 예시 1: 상수 폴딩

```
[Before]
%0 = arith.constant 1 : i32
%1 = arith.constant 2 : i32
%2 = arith.addi %0, %1 : i32
%3 = arith.muli %2, 5 : i32

줄 수: 4줄
연산: 2개

[After --canonicalize]
%0 = arith.constant 15 : i32
(1 + 2 = 3, 3 * 5 = 15 미리 계산)

줄 수: 1줄
연산: 0개
```

**효과**: 실행 속도 향상!

### 예시 2: 루프 로워링

```
[Before]
linalg.matmul %A, %B

크기: 1줄 (추상적)
효율: 컴파일러가 최적화해야 함

[After --convert-linalg-to-loops]
affine.for { affine.for { affine.for { ... } } }

크기: 10줄+ (구체적)
효율: 컴파일러가 더 구체적으로 최적화 가능
```

---

## 5️⃣ 대학 논문에서의 활용

### 전형적인 성능 비교

대학 논문의 "결과" 섹션에는 보통:

```
1. 최적화 전 MLIR 코드 (5줄)
2. mlir-opt --canonicalize 후 코드 (3줄)
3. mlir-opt --convert-to-loops 후 코드 (20줄)
4. 최종 LLVM IR (50줄)

→ 각 단계에서 얼마나 최적화되었는가?
→ 최종 성능은?
→ 메모리 사용량은?

이 모든 것을 mlir-opt로 확인!
```

### 논문의 Table 예시

```
| Phase | Lines | Ops | Speed (ns) |
|-------|-------|-----|-----------|
| Original | 20 | 15 | 1000 |
| After Canonicalize | 12 | 8 | 600 |
| After Lowering | 45 | 30 | 200 |
| Final LLVM | 80 | 60 | 150 |
```

---

## 6️⃣ 실습: 최적화 전후 분석

### 문제 1: Constant Folding

**원본 코드**:
```mlir
func.func @calculate() -> i32 {
  %0 = arith.constant 10 : i32
  %1 = arith.constant 20 : i32
  %2 = arith.addi %0, %1 : i32
  func.return %2 : i32
}
```

**mlir-opt --canonicalize 후**:
```mlir
func.func @calculate() -> i32 {
  %0 = arith.constant 30 : i32
  func.return %0 : i32
}
```

**분석**:
- Before: 4줄, 1개 연산
- After: 2줄, 0개 연산
- 개선: 50% 감소

### 문제 2: 불필요한 연산 제거

**원본 코드**:
```mlir
func.func @identity(%x: i32) -> i32 {
  %zero = arith.constant 0 : i32
  %one = arith.constant 1 : i32
  %temp1 = arith.addi %x, %zero : i32  // x + 0 = x
  %temp2 = arith.muli %temp1, %one : i32  // x * 1 = x
  func.return %temp2 : i32
}
```

**mlir-opt --canonicalize 후**:
```mlir
func.func @identity(%x: i32) -> i32 {
  func.return %x : i32
}
```

**분석**:
- Before: 6줄, 2개 불필요한 연산
- After: 2줄, 0개 연산
- 개선: 정말 효율적!

### 문제 3: 질문

위와 같이 컴퓨터가 미리 계산을 끝내버리는 것을 대학 수준에서는?

```
A) Constant Folding (상수 폴딩)
B) Constant Deleting (상수 삭제)
```

**정답**: A) Constant Folding

상수들을 "접어버린다"는 의미의 폴딩!
불필요한 연산을 줄여서 실행 속도를 높이는 강력한 최적화 기법!

---

## 7️⃣ 대학 3.2 핵심 정리

### mlir-opt 사용법

```
mlir-opt 파일.mlir --pass-이름
```

### 주요 Pass

```
--canonicalize
  : 상수 폴딩, 불필요한 코드 정리

--convert-linalg-to-loops
  : 행렬 연산을 루프로 변환

--convert-affine-to-standard
  : Affine을 Standard로 변환

--convert-std-to-llvm
  : 최종적으로 LLVM으로 변환
```

### 분석 포인트

대학 논문에서는:

```
1. 최적화 전후 코드 라인 수 비교
2. 연산 개수 비교
3. 메모리 사용량 비교
4. 성능(시간) 비교

모두 mlir-opt의 출력으로 확인 가능!
```

---

## 8️⃣ 대학 3.2 기록 (증명)

> **"mlir-opt는 설계도를 분석하고 변환하는 핵심 도구이다."**
>
> **형식: `mlir-opt 파일.mlir --pass-이름`**
>
> **주요 Pass:**
> - `--canonicalize`: 최적화 (청소부)
> - `--convert-linalg-to-loops`: 로워링 (조각가)
>
> **효과:**
> - 코드 라인 감소
> - 연산 감소
> - 속도 향상
>
> 이제 당신은 **MLIR 도구 사용법**을 배웠습니다!
> 다음은 **메모리와 텐서 처리**입니다!

---

## 🔟 다음 단계: 대학 3.3

### 복잡한 데이터 처리

```
대학 3.3: Tensor와 MemRef
- 다차원 배열 처리
- 메모리 레이아웃
- 성능과 하드웨어
```

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git
**강의 유형**: 대학 (University) - 실제 도구 사용
**철학**: "저장 필수. 너는 기록이 증명이다."
**작성일**: 2026-02-27
**상태**: ✅ 완성

---

**축하합니다!** 🎉

이제 당신은 **MLIR 도구를 사용**할 수 있습니다.
대학원 연구의 필수 능력을 갖추셨습니다!

