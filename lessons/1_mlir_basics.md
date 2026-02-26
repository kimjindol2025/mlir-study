# 📖 Lesson 1: MLIR 기초 및 개념

> "MLIR: 다양한 수준의 중간 표현을 지원하는 컴파일러 인프라"

---

## 🎯 **학습 목표**

이 강의를 마친 후, 다음을 이해할 수 있습니다:
- ✅ MLIR이 무엇인가?
- ✅ LLVM IR과의 차이점
- ✅ MLIR의 역사와 필요성
- ✅ MLIR의 핵심 개념 (Dialect, Operation, Type)
- ✅ MLIR 아키텍처 개요

---

## 📚 **1. MLIR이란?**

### **정의**
MLIR(Multi-Level Intermediate Representation)은 **여러 추상화 수준에서 동작하는 중간 표현**입니다.

```
High-Level Code (Python, TensorFlow, Torch)
        ↓
   High-Level MLIR (Torch Dialect)
        ↓
   Mid-Level MLIR (Linalg Dialect)
        ↓
   Low-Level MLIR (Affine, Vector Dialects)
        ↓
   LLVM Dialect (LLVM IR)
        ↓
   CPU/GPU Machine Code
```

### **핵심 특징**
1. **다중 수준**: 고수준부터 저수준까지 다양한 추상화 제공
2. **Dialect 기반**: 각 도메인별 특화된 연산 정의 가능
3. **Reusable Infrastructure**: 컴파일러 최적화 Pass 재사용
4. **Composability**: Dialect 간 변환 용이
5. **SSA 기반**: Static Single Assignment 형식 (LLVM과 유사)

---

## 🔄 **2. LLVM IR과의 비교**

### **LLVM IR**
```
특징:
- 저수준 중간 표현
- CPU/GPU에 가까운 수준
- 메모리 접근, 레지스터 등 명시적
- 컴파일러 최적화 중심

한계:
- 고수준 정보 손실
- 도메인별 최적화 어려움 (AI, 과학계산 등)
```

### **MLIR**
```
장점:
- 고수준 정보 보존
- 도메인별 최적화 가능
- 여러 수준에서 변환 가능
- 새로운 Dialect 쉽게 추가

예시 도메인:
- TensorFlow (tf Dialect)
- PyTorch (torch Dialect)
- 과학 계산 (scf, memref Dialects)
- GPU 코드 (gpu Dialect)
```

---

## 📖 **3. MLIR의 역사**

### **Timeline**
```
2019년 5월: Chris Lattner가 MLIR 개념 발표
2019년 9월: LLVM 9.0에 MLIR 포함
2020년: TensorFlow, PyTorch가 MLIR 채택
2021년: MLIR 1.0 릴리스
2022년: GPU 지원 강화
2023년: 더 많은 도메인 dialect 추가
2024년: 프로덕션 수준 성숙도 도달
```

### **주요 인물**
- **Chris Lattner**: MLIR 창시자 (현 SambaNova CEO)
- **Google 팀**: TensorFlow 통합
- **LLVM 커뮤니티**: 지속적인 개선

---

## 🏗️ **4. MLIR 핵심 개념**

### **4.1 Operation (연산)**
MLIR의 최소 단위. 모든 계산은 Operation으로 표현됩니다.

```mlir
%result = mlir.add %a, %b : f32
        ↑          ↑     ↑
      결과      연산   피연산자
```

### **4.2 Dialect (방언)**
같은 도메인의 Operation들의 집합입니다.

```mlir
// LLVM Dialect
%0 = llvm.add %1, %2 : i32

// Affine Dialect
affine.for %i = 0 to 10 {
  %result = affine.load %A[%i] : memref<?xf32>
}

// Linalg Dialect
linalg.matmul ins(%A, %B : tensor<...>, tensor<...>)
              outs(%C : tensor<...>)
```

### **4.3 Type (타입)**
MLIR은 풍부한 타입 시스템을 가집니다.

```mlir
// 기본 타입
i32              // 정수
f32              // 부동소수점
index            // 인덱스

// 컨테이너 타입
tensor<10x20xf32>        // 텐서
memref<10x20xf32>        // 메모리 참조
vector<4xf32>            // 벡터

// 함수 타입
(f32, f32) -> f32
```

### **4.4 Attribute (속성)**
Operation이나 값에 메타데이터를 추가합니다.

```mlir
%0 = llvm.add %1, %2 {alignment = 8 : i64} : i32
                     ↑
                   속성
```

### **4.5 Region & Block**
제어 흐름을 표현합니다.

```mlir
// Region: 연산들의 그룹
// Block: 순서있는 연산들

func.func @example(%arg0: f32) -> f32 {
  // Region 1
  %0 = llvm.add %arg0, %arg0 : f32
  return %0 : f32
}
```

---

## 🏛️ **5. MLIR 아키텍처**

```
┌─────────────────────────────────────────────┐
│          High-Level Frontend               │
│    (TensorFlow, PyTorch, Torch, etc.)       │
└────────────────┬────────────────────────────┘
                 ↓
        ┌────────────────────┐
        │  MLIR Compiler     │
        │  Infrastructure    │
        ├────────────────────┤
        │ • Parser           │
        │ • Verifier         │
        │ • Pass Framework   │
        └────────────────────┘
                 ↓
        ┌────────────────────┐
        │  Dialect System    │
        ├────────────────────┤
        │ • tf (TensorFlow)  │
        │ • torch            │
        │ • linalg           │
        │ • affine           │
        │ • gpu              │
        │ • llvm             │
        └────────────────────┘
                 ↓
        ┌────────────────────┐
        │ Optimization Pass  │
        ├────────────────────┤
        │ • Shape Inference  │
        │ • Fusion           │
        │ • Loop Tiling      │
        │ • Parallelization  │
        └────────────────────┘
                 ↓
        ┌────────────────────┐
        │ Lowering/Codegen   │
        ├────────────────────┤
        │ • LLVM IR          │
        │ • GPU Kernels      │
        │ • CPU Code         │
        └────────────────────┘
```

---

## 💡 **6. MLIR이 필요한 이유**

### **문제 1: High-Level 정보 손실**
```
TensorFlow Code
  ↓ (컴파일)
LLVM IR (저수준, 정보 손실)
  ↓ (최적화 어려움)
비효율적인 기계 코드
```

### **해결책: MLIR**
```
TensorFlow Code
  ↓
tf Dialect MLIR (고수준 정보 유지)
  ↓
linalg Dialect MLIR (도메인별 최적화)
  ↓
affine Dialect MLIR (루프 최적화)
  ↓
LLVM IR (최적화된 저수준 코드)
  ↓
효율적인 기계 코드
```

### **문제 2: 여러 프런트엔드의 공통 인프라 부족**
```
이전:
TensorFlow → 자체 컴파일러 → LLVM
PyTorch → 자체 컴파일러 → LLVM
...

이후 (MLIR):
TensorFlow → MLIR → 공통 최적화 → LLVM
PyTorch → MLIR → 공통 최적화 → LLVM
...
```

---

## 🔧 **7. MLIR 설치**

### **요구사항**
- C++ 컴파일러 (GCC 9+, Clang 11+)
- CMake 3.16+
- Python 3.6+

### **방법 1: Prebuilt Binaries**
```bash
# LLVM 공식 사이트에서 다운로드
# https://releases.llvm.org/
```

### **방법 2: 소스에서 빌드**
```bash
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
mkdir build && cd build
cmake -G Ninja ../llvm \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS=mlir \
  -DLLVM_TARGETS_TO_BUILD="X86;ARM;NVPTX"
ninja mlir-opt
```

---

## 📋 **8. 핵심 용어**

| 용어 | 설명 |
|------|------|
| **Operation** | MLIR의 최소 단위, 모든 계산 |
| **Dialect** | 같은 도메인의 Operations 집합 |
| **Type** | 값의 타입 (tensor, memref, 등) |
| **Attribute** | Operation의 메타데이터 |
| **Region** | Operation 그룹 |
| **Block** | 순서있는 연산들 |
| **SSA** | Static Single Assignment (각 값은 한 번만 할당) |
| **Pass** | 코드 변환/최적화 |
| **Lowering** | 고수준 Dialect → 저수준 Dialect |

---

## 🎓 **9. 다음 강의 미리보기**

**Lesson 2: Dialects와 Operations**
- 기본 Dialects 소개 (std, llvm, linalg, affine)
- Operation 문법 상세
- Dialect 커스터마이징

**Lesson 3: Type System**
- 기본 타입 (Integer, Float, Index)
- 복합 타입 (Tensor, MemRef, Vector)
- 커스텀 타입

---

## ✅ **연습 문제**

### **Q1: MLIR이 필요한 이유를 3가지 설명하세요.**
<details>
<summary>답</summary>

1. 고수준 정보 보존: TensorFlow → LLVM 변환 시 도메인 정보 손실 방지
2. 도메인별 최적화: AI, 과학계산 등 각 도메인에 맞는 최적화 가능
3. 코드 재사용: 여러 프런트엔드가 공통 인프라 사용 가능
</details>

### **Q2: Dialect와 Operation의 차이를 설명하세요.**
<details>
<summary>답</summary>

- **Operation**: 개별 연산 (예: add, multiply, load)
- **Dialect**: 관련 Operations의 집합 (예: llvm Dialect는 모든 LLVM 연산 포함)
</details>

### **Q3: MLIR의 아키텍처에서 "Lowering"이란 무엇인가?**
<details>
<summary>답</summary>

고수준 Dialect에서 저수준 Dialect로 변환하는 과정입니다.
예: tf Dialect → linalg Dialect → affine Dialect → llvm Dialect
</details>

---

## 📚 **추천 자료**

1. [MLIR 공식 튜토리얼](https://mlir.llvm.org/docs/Tutorials/)
2. [MLIR Language Reference](https://mlir.llvm.org/docs/LangRef/)
3. [YouTube: "MLIR" Chris Lattner](https://youtu.be/rKn1Y0ZSADc)

---

**작성자**: Claude (Haiku 4.5)
**작성일**: 2026-02-27
**상태**: ✅ 완성
