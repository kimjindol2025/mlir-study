# 📦 [대학원 4.5] 기록이 증명이다: Lit & FileCheck Testing

> **MLIR 대학원의 최종 단계: 연구의 신뢰성 증명**
>
> "저장 필수. 너는 기록이 증명이다."
>
> 아무리 훌륭한 최적화 패스를 짰어도,
> 그것이 코드를 망가뜨리지 않고 정확히 변환했다는 것을 보여주지 못하면
> **연구로서 가치가 없습니다**.
>
> MLIR에서는 Lit과 FileCheck이라는 강력한 도구로
> 이를 **기록하고 증명합니다**.

---

## 🎯 오늘 배울 것

한 가지 핵심 개념입니다:

> **"기록이 없으면 증명할 수 없고, 테스트가 없으면 신뢰할 수 없다."**
>
> **"Lit과 FileCheck은 내 설계의 무결성을 증명하는 연구자의 마지막 방패다."**

---

## 1️⃣ FileCheck: 설계자의 의도 확인

### FileCheck란?

```
FileCheck = 자동 검증 도구

입력: .mlir 파일 (주석으로 기댓값 포함)
처리: 패스 실행 후 결과 생성
검증: 기댓값과 실제 결과 비교
출력: PASS / FAIL
```

### 기본 문법

```mlir
// RUN: mlir-opt %s --my-pass | FileCheck %s

func.func @test(%arg0: f32) -> f32 {
  // CHECK: arith.addf
  // CHECK-NOT: arith.mulf
  %0 = arith.addf %arg0, %arg0 : f32
  return %0 : f32
}
```

**의미**:
```
// RUN: mlir-opt %s --my-pass | FileCheck %s
→ 이 파일을 my-pass로 변환한 후, FileCheck로 검증

// CHECK: arith.addf
→ 결과에 "arith.addf"가 반드시 있어야 함

// CHECK-NOT: arith.mulf
→ 결과에 "arith.mulf"가 없어야 함
```

### FileCheck의 종류

```
// CHECK:           이 텍스트가 정확히 나타나야 함
// CHECK-NOT:       이 텍스트가 나타나면 안 됨
// CHECK-NEXT:      다음 줄에 이 텍스트가 있어야 함
// CHECK-SAME:      같은 줄에 이 텍스트가 있어야 함
// CHECK-DAG:       임의의 순서로 나타나면 됨
// CHECK-LABEL:     라벨 체크 (함수명 등)
```

---

## 2️⃣ 실전 예제 1: 상수 폴딩 검증

### 테스트 코드

```mlir
// RUN: mlir-opt %s --canonicalize | FileCheck %s

func.func @test_constant_folding() -> i32 {
  %c1 = arith.constant 1 : i32
  %c2 = arith.constant 2 : i32
  // CHECK: arith.constant 3
  // CHECK-NOT: arith.addi
  %0 = arith.addi %c1, %c2 : i32
  return %0 : i32
}
```

**작동 방식**:
```
[Before Optimization]
%c1 = arith.constant 1 : i32
%c2 = arith.constant 2 : i32
%0 = arith.addi %c1, %c2 : i32
return %0 : i32

[mlir-opt --canonicalize 실행]
→ 상수 폴딩 적용

[After Optimization]
%0 = arith.constant 3 : i32
return %0 : i32

[FileCheck 검증]
✓ "arith.constant 3" 있음 → CHECK 통과
✓ "arith.addi" 없음 → CHECK-NOT 통과
→ 테스트 PASS!
```

---

## 3️⃣ 실전 예제 2: Operation Fusion 검증

### 당신의 MatMul+ReLU Fusion 검증

```mlir
// RUN: mlir-opt %s --fuse-matmul-relu | FileCheck %s

func.func @test_fusion(%A: tensor<4x4xf32>, %B: tensor<4x4xf32>) -> tensor<4x4xf32> {
  // Fused operation이 나타나야 함
  // CHECK: my.matmul_relu
  // 원래의 분리된 연산들이 없어야 함
  // CHECK-NOT: linalg.matmul
  // CHECK-NOT: linalg.relu

  %C = linalg.matmul %A, %B : (tensor<4x4xf32>, tensor<4x4xf32>) -> tensor<4x4xf32>
  %D = linalg.relu %C : tensor<4x4xf32>
  return %D : tensor<4x4xf32>
}
```

**검증 순서**:
```
원본 코드:
  linalg.matmul
  linalg.relu

패스 실행 후:
  my.matmul_relu (fusion!)

FileCheck:
  ✓ "my.matmul_relu" 찾음 → CHECK 통과
  ✓ "linalg.matmul" 없음 → CHECK-NOT 통과
  ✓ "linalg.relu" 없음 → CHECK-NOT 통과
  → 테스트 PASS!
```

---

## 4️⃣ 실전 예제 3: 병렬화 가능성 표시

```mlir
// RUN: mlir-opt %s --analyze-parallelization | FileCheck %s

func.func @test_loop_independence() {
  %c0 = arith.constant 0 : index
  %c10 = arith.constant 10 : index
  %c1 = arith.constant 1 : index

  // 병렬화 가능한 루프
  // CHECK: "parallelizable"
  scf.for %i = %c0 to %c10 step %c1 {
    %a = arith.addi %i, %i : index
    scf.yield
  }

  return
}
```

**검증 내용**:
```
패스 실행 후:
  scf.for 연산에 "parallelizable" 속성이 추가됨

FileCheck:
  ✓ "parallelizable" 속성 확인 → CHECK 통과
  → 루프가 실제로 분석되고 표시됨을 증명!
```

---

## 5️⃣ 실전 예제 4: 메모리 배치 최적화 검증

```mlir
// RUN: mlir-opt %s --npu-memory-optimization | FileCheck %s

func.func @test_memory_optimization() {
  %A = memref.alloc() : memref<1000xf32>
  %B = memref.alloc() : memref<1000xf32>

  // 최적화 후: 메모리가 재할당되어야 함
  // CHECK: memref.alloc
  // 할당 개수는 줄어들어야 함 (원래 2개 → 1개 또는 통합)

  return
}
```

---

## 6️⃣ Lit: 자동 채점기

### Lit의 역할

```
Lit = LLVM Integrated Tester

역할:
├─ 수백 개의 테스트 파일 자동 실행
├─ 각 파일마다 FileCheck 검증
├─ 전체 성적표 생성 (PASS/FAIL count)
└─ 상세 리포트 출력
```

### 테스트 구조

```
tests/
├── CMakeLists.txt          ← Lit 설정
├── unit/
│   ├── canonicalize.mlir   ← 상수 폴딩 테스트
│   ├── fusion.mlir         ← Fusion 테스트
│   └── parallelization.mlir ← 병렬화 테스트
└── integration/
    ├── end-to-end.mlir     ← 전체 파이프라인 테스트
    └── performance.mlir    ← 성능 테스트
```

### CMakeLists.txt 설정

```cmake
# tests/CMakeLists.txt

configure_lit_site_cfg(
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py
  MAIN_CONFIG
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py
)

add_lit_testsuite(check-mlir-dialect
  "Running MLIR dialect tests"
  ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS
  MyDialect
  my-mlir-opt
)
```

### 실행

```bash
$ cd build
$ lit tests/

# 출력:
# ======================================================================
# Test Summary
# ======================================================================
# Total Dirs  : 2
# Total Tests : 25
# Passed      : 24
# Failed      : 1
#
# FAILED: tests/integration/end-to-end.mlir
```

---

## 7️⃣ 전체 파이프라인 복습

### 당신의 여정을 한눈에 보기

```
┌─────────────────────────────────────────────────┐
│ Step 1: 설계 명세 (4.1 TableGen)                │
│ ─────────────────────────────────────────────   │
│ def MyAddOp : MyDialect_Op<"my_add"> {         │
│   let arguments = (ins F32:$lhs, F32:$rhs);    │
│   let results = (outs F32:$result);            │
│ }                                               │
│ → 나만의 언어와 규칙을 선언                      │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Step 2: 구조 설계 (Dialect & Op)               │
│ ─────────────────────────────────────────────   │
│ module {                                        │
│   func @test(%arg0: f32) -> f32 {              │
│     %0 = my.my_add %arg0, %arg0 : f32          │
│     return %0 : f32                            │
│   }                                            │
│ }                                               │
│ → module, func, op의 계층 구조                  │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Step 3: 지능 부여 (4.2 DRR & 4.4 C++ Pass)    │
│ ─────────────────────────────────────────────   │
│ def FusionRule : Pat<...>                      │
│ struct MyPass : public OperationPass<...>      │
│ → 최적화 알고리즘 이식                          │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Step 4: 하드웨어 연결 (Lowering)               │
│ ─────────────────────────────────────────────   │
│ tensor<4x4xf32>                                │
│   ↓ bufferization                              │
│ memref<4x4xf32>                                │
│   ↓ lowering                                   │
│ LLVM IR                                        │
│   ↓ llc                                        │
│ 기계어                                          │
│ → 텐서를 메모리로, LLVM IR로 도달               │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Step 5: 검증 (4.5 FileCheck & Lit) ← 당신!   │
│ ─────────────────────────────────────────────   │
│ // RUN: mlir-opt %s --my-pass | FileCheck %s   │
│ // CHECK: my.result                            │
│ // CHECK-NOT: my.old_operation                 │
│ → 내 설계의 무결성 증명                         │
└─────────────────────────────────────────────────┘
```

---

## 8️⃣ 졸업 퀴즈: 심사위원의 마지막 질문

### 질문
"당신이 만든 새로운 Dialect가 기존의 LLVM 생태계와 왜 잘 어울린다고 생각합니까?"

### 선택지

```
A) "제 마음대로 만들었기 때문입니다."

B) "MLIR의 표준화된 인프라 위에서 설계했으므로,
   제가 만든 Dialect도 결국 mlir-opt와 LLVM의
   수많은 최적화 도구를 그대로 활용할 수 있기 때문입니다."
```

### 정답: B) ✅

**이유**:
```
MLIR의 위대함:
─────────────

당신이 직접 만든 것:
✅ MyDialect (설계 명세)
✅ MyOp (새로운 연산)
✅ MyPass (최적화 알고리즘)
✅ MyFusion (Operation Fusion)

당신이 사용한 MLIR 인프라:
✅ PassManager (패스 실행 프레임워크)
✅ Lowering (텐서→메모리)
✅ mlir-opt (최적화 도구)
✅ LLVM Backend (기계어 생성)
✅ FileCheck (테스트 프레임워크)

→ 당신의 새로운 Dialect는
  기존 MLIR 생태계 위에서
  자동으로 이 모든 도구를 활용 가능!

= MLIR이 거인의 어깨 역할을 함
```

---

## 9️⃣ 대학원 4.5 핵심 정리

### FileCheck의 강력함

```
FileCheck 없이:
"제 최적화는 작동합니다!"
→ 증거 없음, 신뢰 불가

FileCheck 있음:
// RUN: mlir-opt %s --my-pass | FileCheck %s
// CHECK: expected_result
// CHECK-NOT: dead_code
→ 자동 검증, 증명 가능!
```

### Lit의 역할

```
단순 테스트:
몇 개 파일 손으로 확인

Lit 자동화:
수백 개 테일 한 번에 실행
상세 보고서 생성
CI/CD 통합 가능
```

### 연구의 신뢰성

```
테스트 = 증거
증거 = 신뢰
신뢰 = 학위
```

---

## 🔟 대학원 4.5 기록 (증명)

> **"기록이 없으면 증명할 수 없고, 테스트가 없으면 신뢰할 수 없다."**
>
> **"Lit과 FileCheck은 내 설계의 무결성을 증명하는 연구자의 마지막 방패다."**
>
> **FileCheck의 검증:**
> - CHECK: 기댓값 확인
> - CHECK-NOT: 불필요한 코드 제거 확인
> - CHECK-NEXT: 순서 확인
> - CHECK-DAG: 임의 순서 확인
>
> **Lit의 자동화:**
> - 수백 개 테스트 한 번에 실행
> - 자동 채점 및 리포트
> - CI/CD 통합
>
> **MLIR의 거인:**
> - 당신의 새로운 Dialect가
> - 기존 MLIR 생태계와 자동으로 통합됨
>
> 이제 당신은 **완벽한 MLIR 연구자**입니다!

---

## 🎓 박사 과정을 위한 최종 조언

### 당신이 마스터한 것

```
✅ MLIR 전체 생태계 이해
✅ Operation 설계 (TableGen)
✅ 최적화 규칙 (DRR + C++ Pass)
✅ 빌드 시스템 관리 (CMake)
✅ 자동 검증 (FileCheck + Lit)

= MLIR 마스터!
```

### 박사 과정의 길

```
당신이 할 수 있는 것:

1. 새로운 하드웨어 Dialect 설계
   (예: TPU, GPU, NPU 특화 Dialect)

2. 혁신적 최적화 알고리즘
   (예: 메모리 배치, 전력 소모 감소)

3. 완전한 컴파일러 시스템
   (설계 → 구현 → 검증 → 배포)

4. 논문 발표
   "우리의 새로운 Dialect으로 성능 40% 향상!"
```

### 기억할 것

```
"저장 필수. 너는 기록이 증명이다."

모든 것을 기록하라:
- 설계 명세 (.td 파일)
- 최적화 알고리즘 (C++ Pass)
- 테스트 코드 (FileCheck)
- 성능 결과 (벤치마크)

기록이 당신의 논문이 된다!
기록이 당신의 학위가 된다!
```

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git
**강의 유형**: 대학원 (Graduate) - 최종 검증과 배포
**철학**: "저장 필수. 너는 기록이 증명이다."
**작성일**: 2026-02-27
**상태**: ✅ 완성

---

**축하합니다!** 🎉

당신은 이제 **MLIR의 모든 것**을 마스터했습니다.
초등부터 대학원까지, 완벽한 여정을 마쳤습니다.

이제 당신은 **세상에 없던 새로운 컴퓨팅 시스템**을 설계할 준비가 끝났습니다!
