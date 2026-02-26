# 📦 [중등 2.2] 가장 큰 주머니: Module(모듈)

> **MLIR의 중등 두 번째 단계: 모든 것을 담는 공장**
>
> "저장 필수. 너는 기록이 증명이다."
>
> 지금까지 우리는:
> - 초등: %이름표, Dialect.도구, :타입
> - 중등 2.1: func.func 함수
>
> 이제 이 모든 것을 하나의 파일로 만드는 **가장 큰 틀**인 모듈을 배웁니다!

---

## 🎯 오늘 배울 것

단 하나의 개념입니다:

> **"모든 MLIR 파일은 module { ... }로 감싼다."**
>
> **형식: module { func { operations } }**

---

## 1️⃣ 상상해 보세요

### 공장의 비유

```
┌─────────────────────────────────┐
│         공장 건물 (Module)        │
│                                 │
│  ┌──────────────┐              │
│  │  기계 1      │ ← func.func   │
│  │  ┌────────┐  │              │
│  │  │ 도구   │  │ ← arith.xxx  │
│  │  │ 재료   │  │ ← %값        │
│  │  └────────┘  │              │
│  └──────────────┘              │
│                                 │
│  ┌──────────────┐              │
│  │  기계 2      │ ← func.func   │
│  │  ┌────────┐  │              │
│  │  │ 도구   │  │              │
│  │  │ 재료   │  │              │
│  │  └────────┘  │              │
│  └──────────────┘              │
│                                 │
└─────────────────────────────────┘
```

### Module의 역할

- 공장 건물의 외벽 (시작과 끝)
- 여러 기계(함수)를 보호
- 기계들끼리 소통 가능
- 하나의 완전한 프로그램

---

## 2️⃣ MLIR의 전체 구조 (완성판)

### 레이어 구조

```
Layer 1: module (공장)
  ↓
Layer 2: func.func (기계)
  ↓
Layer 3: operations (도구)
  ↓
Layer 4: types (재료)
```

### 실제 코드로 보기

```mlir
// Layer 1: 공장을 세웁니다
module {

  // Layer 2: 기계를 설치합니다
  func.func @smart_calculator(%arg0: f32) -> f32 {

    // Layer 3: 도구를 써서 계산합니다
    %cst = arith.constant 1.0 : f32          // 상수 준비
    %result = arith.addf %arg0, %cst : f32   // 더하기

    // Layer 4: 타입을 명시합니다
    func.return %result : f32                 // 반환
  }

}
```

### 각 부분의 의미

```
module                           ← 공장의 외벽
│
├─ func.func @add               ← 첫 번째 기계
│  ├─ %arg0: f32              ← 입력 재료 (타입)
│  ├─ arith.addf              ← 도구
│  ├─ %result                 ← 임시 결과물
│  └─ func.return             ← 완성품 내보내기
│
├─ func.func @multiply         ← 두 번째 기계
│  └─ ...
│
└─ (더 많은 기계들)
```

---

## 3️⃣ Module과 Hierarchy

### MLIR의 계층 구조 (대학원 수준)

```
Module (영역)
├─ Region 0 (공장의 내부)
   ├─ Block 0 (기계들의 모음)
      ├─ Operation 0: func.func @add
      │  └─ Region 0 (함수의 내부)
      │     └─ Block 0 (명령어들)
      │        ├─ Operation: arith.addf
      │        └─ Operation: func.return
      │
      └─ Operation 1: func.func @multiply
```

### 현재 알아야 할 것

```
module { }       ← 가장 바깥쪽 껍질
  func.func { } ← 그 안의 기계
    operations  ← 기계 안의 도구들
```

---

## 4️⃣ 여러 함수를 가진 모듈

### 예제 1: 2개 함수

```mlir
module {
  // 기계 1: 더하기
  func.func @add(%a: i32, %b: i32) -> i32 {
    %sum = arith.addi %a, %b : i32
    func.return %sum : i32
  }

  // 기계 2: 곱하기
  func.func @multiply(%x: i32, %y: i32) -> i32 {
    %prod = arith.muli %x, %y : i32
    func.return %prod : i32
  }
}
```

**특징**:
- module 안에 2개 함수
- 각 함수는 독립적
- 같은 공간 안에 있음

### 예제 2: 함수 호출

```mlir
module {
  // 기계 1: 기본 계산
  func.func @step1(%input: i32) -> i32 {
    %doubled = arith.muli %input, 2 : i32
    func.return %doubled : i32
  }

  // 기계 2: 다른 기계 사용
  func.func @step2(%input: i32) -> i32 {
    // @step1 기계를 호출하여 결과를 받음
    %intermediate = func.call @step1(%input) : (i32) -> i32

    // 그 결과에 10을 더함
    %const = arith.constant 10 : i32
    %final = arith.addi %intermediate, %const : i32

    func.return %final : i32
  }
}
```

**특징**:
- func.call로 다른 함수 호출
- @step1 (기계 이름)으로 호출
- 함수 간 데이터 이동

### 예제 3: 복잡한 계산 파이프라인

```mlir
module {
  // Step 1: 기본 연산
  func.func @compute_base(%x: f32) -> f32 {
    %two = arith.constant 2.0 : f32
    %result = arith.mulf %x, %two : f32
    func.return %result : f32
  }

  // Step 2: 보정 추가
  func.func @apply_correction(%value: f32) -> f32 {
    %correction = arith.constant 0.5 : f32
    %result = arith.addf %value, %correction : f32
    func.return %result : f32
  }

  // Step 3: 전체 파이프라인
  func.func @full_pipeline(%input: f32) -> f32 {
    %step1_result = func.call @compute_base(%input) : (f32) -> f32
    %step2_result = func.call @apply_correction(%step1_result) : (f32) -> f32
    func.return %step2_result : f32
  }
}
```

**특징**:
- 3개 함수의 조합
- 파이프라인 구조
- 순차적 처리

---

## 5️⃣ 대학원 수준: Symbol(@) vs Value(%)

### 핵심 차이

| 구분 | 기호 | 범위 | 변함 | 예시 |
|------|------|------|------|------|
| Symbol | @ | 공장 전체 | 아님 | @add, @multiply |
| Value | % | 함수 내부 | 계속 | %arg0, %result |

### 개념 이해

```
@add (Symbol - 기호)
└─ 공장의 고정된 기계
└─ 공장 어디서든 부를 수 있음
└─ 평생 같은 기계
└─ 대학원 관점: "설계도 수준의 이름"

%0 (Value - 값)
└─ 함수 안의 임시 결과
└─ 그 함수 안에서만 쓸 수 있음
└─ 계속 변함
└─ 대학원 관점: "실행 시간에 생기는 데이터"
```

### 실제 비유

```
공장:
@machines     ← Symbols (고정된 기계들의 이름)
  │
  ├─ @add (항상 같은 덧셈 기계)
  ├─ @multiply (항상 같은 곱셈 기계)
  └─ ...

기계 내부:
%data        ← Values (들어올 재료들)
  │
  ├─ %arg0 (입력된 첫 번째 재료)
  ├─ %result (만들어진 임시 결과)
  └─ ...
```

---

## 6️⃣ 올바른 구조 vs 틀린 구조

### ✅ 올바른 구조 1

```mlir
module {
  func.func @add(%a: i32, %b: i32) -> i32 {
    %sum = arith.addi %a, %b : i32
    func.return %sum : i32
  }
}
```

✅ module로 시작
✅ func.func로 함수 선언
✅ @ 기호 있음
✅ % 기호 있음
✅ 닫는 괄호 있음

### ✅ 올바른 구조 2

```mlir
module {
  func.func @step1(%x: i32) -> i32 {
    %temp = arith.addi %x, 1 : i32
    func.return %temp : i32
  }

  func.func @step2(%y: i32) -> i32 {
    %result = func.call @step1(%y) : (i32) -> i32
    func.return %result : i32
  }
}
```

✅ 하나의 module에 여러 함수
✅ func.call로 함수 호출
✅ @ 기호로 함수 참조

### ❌ 틀린 구조 1: module 없음

```mlir
❌ func.func @add(%a: i32, %b: i32) -> i32 {
  %sum = arith.addi %a, %b : i32
  func.return %sum : i32
}
```

ERROR: 모든 MLIR은 module로 감싸야 함!

### ❌ 틀린 구조 2: 함수 호출 형식 틀림

```mlir
module {
  func.func @step1(%x: i32) -> i32 {
    %temp = arith.addi %x, 1 : i32
    func.return %temp : i32
  }

  func.func @step2(%y: i32) -> i32 {
    ❌ %result = func.call step1(%y)  ← @ 없음!
    func.return %result : i32
  }
}
```

ERROR: 함수 호출할 때 @step1처럼 써야 함!

---

## 7️⃣ 중등 2.2의 핵심 정리

### 최종 구조도

```
module {
  ┌─ func.func @func1(args) -> type {
  │    operations
  │    func.return
  │  }
  │
  ├─ func.func @func2(args) -> type {
  │    operations
  │    func.return
  │  }
  │
  └─ ... (더 많은 함수들)
}
```

### 체크리스트

모듈을 작성할 때:

- [ ] module { } 로 감싸졌나요?
- [ ] 함수가 module 안에 있나요?
- [ ] 각 함수가 @ 기호를 가졌나요?
- [ ] 각 변수가 % 기호를 가졌나요?
- [ ] 함수 호출할 때 @함수이름 형식을 사용했나요?
- [ ] 모든 괄호가 올바르게 닫혀있나요?

---

## 8️⃣ MLIR 완벽 기초 정리

### 초등 + 중등 2.1 + 중등 2.2

```
초등 1.1: %이름표
초등 1.2: Dialect.도구
초등 1.3: :타입

중등 2.1: func.func @name(%) -> type { }

중등 2.2: module { func { ops } }

이 모든 것이 모여서 하나의 완전한 MLIR 프로그램!
```

### 기호 정리

```
%     ← 값 (Value) - 함수 내부에서만 유효
@     ← 기호 (Symbol) - 공장 전체에서 유효
.     ← Dialect 연결
:     ← 타입 명시
->    ← 반환 타입
{ }   ← 범위 표시
```

---

## 9️⃣ 중등 2.2 기록 (증명)

> **"MLIR 파일의 시작과 끝은 module { ... }로 감싼다."**
>
> **"고정된 이름(함수 등)은 @를 쓰고, 변하는 값은 %를 쓴다."**
>
> **Symbol (@) vs Value (%)**
> - @ 는 공장 전체에서 접근 가능한 고정된 이름
> - % 는 함수 내부의 임시 값
>
> 이제 당신은 MLIR의 **외형(Syntax)을 완벽히 마스터**했습니다!
> 다음부터는 이 설계도를 진짜로 실행하는 **컴파일과 최적화**를 배웁니다!

---

## 🔟 다음 단계: 대학 과정 3.1

### 대학 과정으로 진입

```
대학 3.1: Pass와 최적화
- 작성한 MLIR을 어떻게 개선할까?
- 컴파일러 최적화의 원리
- 성능 향상 기법
```

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git
**강의 유형**: 중등 (Intermediate)
**철학**: "저장 필수. 너는 기록이 증명이다."
**작성일**: 2026-02-27
**상태**: ✅ 완성

---

**축하합니다!** 🎉

당신은 중등 과정을 완료했습니다.
이제 **MLIR의 모든 기초 문법**을 알게 되었습니다!

