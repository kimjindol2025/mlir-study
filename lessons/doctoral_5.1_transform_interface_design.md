# 🎓 박사 5.1: Transform Dialect & Interface 설계 - 동적 최적화의 정점

**작성일**: 2026-02-27 | **수준**: Doctoral (박사) | **목표 시간**: 2시간 | **줄수**: 520줄

---

## 📚 핵심 개념: Transform Dialect와 Interface의 철학

### 1️⃣ Transform Dialect란?

#### 정의
```
Transform Dialect = "코드를 바꾸는 코드" (Meta-programming at MLIR Level)

과거 컴파일러:
  ┌─────────────┐
  │ 고정된 Pass │ (C++ 코드로 하드코딩)
  │   체인      │
  └─────────────┘
        ↓
  최적화 순서 변경 = C++ 재작성 + 재빌드 (시간이 오래 걸림)

Transform Dialect:
  ┌─────────────────────────────────┐
  │ MLIR 스크립트 (Transform 언어)  │ ← 수정 용이!
  └─────────────────────────────────┘
        ↓
  런타임에 최적화 전략 선택 (rebuild 불필요)
```

#### 핵심 특징
```
1. Meta-programming:
   - MLIR 코드가 MLIR 코드를 조작한다
   - 최적화 순서를 데이터처럼 취급

2. 유연성:
   - C++ 재빌드 없이 최적화 규칙 변경
   - 서로 다른 하드웨어에 맞춘 전략 선택

3. 재현성:
   - 최적화 과정이 명확히 기록된다
   - "저장 필수, 너는 기록이 증명이다"
```

---

## 🎯 Interface: "범용성"의 설계

### 2️⃣ Interface의 철학

#### 문제 상황
```
당신이 "TilingOptimizationPass"를 만들었습니다.
하지만 이것은 당신의 커스텀 MatMul 연산에만 작동합니다.

문제:
  - 다른 연산(Conv2D, Einsum)에는 적용 불가
  - 같은 로직을 반복해서 작성해야 함 (코드 중복)
  - 다른 팀의 새로운 연산이 추가되면?
```

#### 해결책: Interface
```
Interface = "최적화 가능한 연산이 만족해야 할 계약"

예: TilingInterface
  ┌─────────────────────────────┐
  │ TilingInterface (계약)      │
  │  - getIterationDomain()     │
  │  - getTileSizes()           │
  │  - getLoopIteratorTypes()   │
  └─────────────────────────────┘
        ↑                ↑               ↑
      MatMul          Conv2D          Einsum
   (이 Interface를   (이 Interface를   (이 Interface를
    구현합니다)       구현합니다)       구현합니다)

→ 하나의 TilingPass가 모든 연산에 작동!
```

#### Interface의 이점
```
1. 추상화 (Abstraction):
   - 특정 연산에 의존하지 않음
   - "타일링 가능한 모든 연산"에 적용

2. 확장성 (Extensibility):
   - 새로운 연산 추가 시 Interface만 구현
   - 기존 Pass는 수정 불필요

3. 일반화 (Generalization):
   - 박사 논문의 Contribution이 강해짐
   - "어떤 연산이든" 최적화 가능한 구조
```

---

## 💡 Transform Dialect 문법과 사용법

### 3️⃣ Transform Operations 기본

#### 기본 구조
```mlir
// Transform 프로그램 = MLIR 코드로 최적화를 정의

transform.sequence failures(propagate) {
^bb0(%arg0: !transform.any_op):
  // Step 1: 최적화 대상 찾기
  %matmul_ops = transform.structured.match
    ops{["linalg.matmul"]} in %arg0
  : (!transform.any_op) -> !transform.any_op

  // Step 2: Tiling 적용
  %tiled, %loops = transform.structured.tile_using_for %matmul_ops
    tile_sizes [64, 64, 64]
  : (!transform.any_op) -> (!transform.any_op, !transform.any_op)

  // Step 3: Vectorization 적용
  transform.structured.vectorize %tiled
  : (!transform.any_op) -> ()
}
```

#### 주요 Transform Operations
```mlir
1. match: 특정 Operation 찾기
   %ops = transform.structured.match ops{["linalg.matmul"]}

2. tile_using_for: 루프 타일링
   %tiled, %loops = transform.structured.tile_using_for
     tile_sizes [64, 64, 64]

3. vectorize: 벡터화
   transform.structured.vectorize %ops

4. fuse_into_containing_loop: Operation 통합
   transform.structured.fuse_into_containing_loop %op into %loop

5. decompose: 복잡한 연산 분해
   transform.structured.decompose %ops
```

---

## 🔧 Interface 설계: TilingInterface 예제

### 4️⃣ TilingInterface 구현

#### Interface 정의 (TableGen)
```tablegen
// MyDialect.td

def MyTilableOp : MyDialect_Op<"tilable_matmul"> {
  let arguments = (ins
    AnyMemRef:$lhs,
    AnyMemRef:$rhs,
    AnyMemRef:$result
  );

  // TilingInterface 구현 선언
  let traits = [TilingInterface];
}
```

#### C++ 구현
```cpp
// MyDialectOps.cpp

class TilableMatMulOp : public Op<"tilable_matmul">,
                        public TilingInterface {
public:
  // 반드시 구현해야 할 메서드들:

  /// Step 1: 반복 영역(Iteration Domain) 정의
  /// "이 연산은 M x N x K 3차원 공간에서 실행된다"
  SmallVector<Range> getIterationDomain(OpBuilder &b, Location loc) {
    int64_t M = lhs().getType().cast<MemRefType<>>().getDimSize(0);
    int64_t N = rhs().getType().cast<MemRefType<>>().getDimSize(1);
    int64_t K = lhs().getType().cast<MemRefType<>>().getDimSize(1);

    return {
      Range{b.getIndexAttr(0), b.getIndexAttr(M), b.getIndexAttr(1)},
      Range{b.getIndexAttr(0), b.getIndexAttr(N), b.getIndexAttr(1)},
      Range{b.getIndexAttr(0), b.getIndexAttr(K), b.getIndexAttr(1)}
    };
  }

  /// Step 2: 타일 크기 제안
  /// "메모리 제약에서 최대 64x64x64 타일 사용"
  SmallVector<int64_t> getDefaultTileSizes() {
    return {64, 64, 64};
  }

  /// Step 3: 타일된 코드 생성
  /// "타일 경계 내에서 실제 연산 코드 생성"
  FailureOr<TiledAndFusedResult>
  getTiledImplementation(OpBuilder &b,
                         ArrayRef<OpFoldResult> tileSizes) {
    Location loc = getLoc();

    // 타일된 MatMul 구현
    auto tiledOp = b.create<TilableMatMulOp>(
      loc,
      getTiledResult(tileSizes)
    );

    return TiledAndFusedResult{
      tiledOp,
      tiledOp->getResults()
    };
  }
};

// Interface 등록
DialectOp::attachInterface<TilableMatMulOp::TilingInterfaceExternalModel>(
  context);
```

---

## 🏗️ 이기종 하드웨어 컴파일러 구조

### 5️⃣ 박사급 컴파일러 아키텍처

#### 전체 구조
```
┌────────────────────────────────────────────────────────┐
│ Front-end: PyTorch/TensorFlow 모델 입력               │
│ (Dense, Sparse, Dynamic shapes 등)                   │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│ High-level IR (Torch/TF Dialect)                      │
│ "이 모델이 무엇을 하려는가?"                           │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│ Graph-level Optimization (당신의 연구 영역)           │
│ ✅ Operator Fusion (Conv+BN+ReLU)                    │
│ ✅ Memory Planning (재사용률 최대화)                  │
│ ✅ Data Layout Optimization (NCHW ↔ NHWC)           │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│ Mid-level IR (Linalg + Custom Ops)                    │
│ "어떻게 계산하는가?"                                   │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│ Loop-level Optimization (당신의 핵심 연구)            │
│ ✅ Tiling (메모리 계층 활용)                          │
│ ✅ Loop Interchange (캐시 효율성)                    │
│ ✅ Vectorization (SIMD 활용)                         │
│ ✅ Unrolling (Instruction-level 병렬성)             │
│ ✅ Double Buffering (연산-메모리 오버래핑)           │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│ Lowering to Hardware (NPU/GPU/CPU)                    │
│ ✅ DMA 명령 생성                                       │
│ ✅ 동기화(Synchronization) 코드 삽입                 │
│ ✅ 하드웨어별 Instruction 생성                        │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│ Back-end: 바이너리/ISA 코드 생성                      │
│ (NPU firmware, CUDA kernel, CPU assembly 등)         │
└────────────────────────────────────────────────────────┘
```

#### 각 단계의 역할
```
Graph-level:     연산자 단위 최적화 (높은 수준)
Loop-level:      루프 변환 최적화 (중간 수준) ← 당신의 연구
Hardware-level:  하드웨어 매핑 (낮은 수준)
```

---

## ⚡ 고급 최적화: Double Buffering

### 6️⃣ Double Buffering 패턴

#### 개념
```
문제:
  데이터 로드와 연산이 순차적으로 실행되면 성능 낭비

해결책:
  Iteration i:
    - A: 다음 데이터 로드 (DMA)
    - B: 현재 데이터로 연산 (컴퓨팅)
    동시 실행!

패턴:
┌──────────────────────────────────────────┐
│ Iteration 0:                             │
│   Load tile[0] → Compute with prev data │
├──────────────────────────────────────────┤
│ Iteration 1:                             │
│   Load tile[1] → Compute with tile[0]   │
├──────────────────────────────────────────┤
│ Iteration 2:                             │
│   Load tile[2] → Compute with tile[1]   │
└──────────────────────────────────────────┘

메모리 버스 + 컴퓨팅 유닛이 동시에 작동!
```

#### MLIR 코드
```mlir
// Double Buffering 구현 (Affine Dialect)

affine.for %i = 0 to 10 {
  // Phase 1: Prefetch (다음 데이터 미리 로드)
  affine.if %i < 9 {
    %prefetch = memref.load %input[%i + 1] : memref<1000xf32>
    // DMA 명령 발행
    %dma_handle = llvm.call @dma_load(%input, %i + 1) : (memref, index) -> i64
  }

  // Phase 2: Compute (현재 데이터로 연산)
  affine.if %i > 0 {
    %result = arith.mulf %current_tile, %weight : f32
    memref.store %result, %output[%i - 1] : memref<1000xf32>
  }

  // 동기화: DMA 완료 대기
  llvm.call @dma_wait(%dma_handle) : (i64) -> ()
}
```

#### 성능 향상
```
최적화 전: Load + Compute + Load + Compute + ...
           (메모리 버스 유휴, 컴퓨팅 유닛 유휴)

최적화 후: Load ↓ + Compute ↓ + Load ↓ + Compute ↓
           (동시 실행, 유휴 시간 최소화)

성능 향상: 2배까지 가능 (메모리 bound 작업)
```

---

## 🎯 박사급 연구 전략

### 7️⃣ 연구 가설 설정 방법

#### 가설 1: 메모리 제약 하에서 성능 최적화
```
가설:
  "작은 메모리(256MB)를 가진 AI 가속기에서,
   거대한 행렬 곱셈(1000x1000x1000)을 실행할 때,
   TilingInterface + Transform Dialect를 사용하여
   기본 구현 대비 3배 이상의 성능 향상을 달성할 수 있다."

검증:
  ✅ Step 1: TilingInterface 구현
  ✅ Step 2: Transform Dialect로 최적화 순서 정의
  ✅ Step 3: Double Buffering 적용
  ✅ Step 4: FileCheck로 변환 검증
  ✅ Step 5: 벤치마크 결과 증명
```

#### 가설 2: 범용성 (다양한 하드웨어 대응)
```
가설:
  "Interface 기반 설계를 통해,
   하나의 최적화 패스가 CPU, GPU, NPU 모두에서
   작동하게 할 수 있다."

검증 경로:
  ✅ Interface 추상화 수준 분석
  ✅ 서로 다른 하드웨어 특성 반영
  ✅ 각 하드웨어별 Performance Model 구축
  ✅ 자동 최적화 선택 메커니즘
```

---

## 📊 박사 5.1의 핵심 정리

### 8️⃣ 기억할 개념

```
Transform Dialect:
  "MLIR 코드로 최적화 전략을 정의한다"
  → C++ 재빌드 불필요
  → 유연한 최적화 순서 제어

Interface:
  "최적화 가능한 연산이 만족할 계약"
  → TilingInterface, LoopLikeInterface 등
  → 다양한 연산에 동일 Pass 적용

범용성:
  "어떤 하드웨어든 대응 가능한 구조"
  → Interface + Transform Dialect
  → 박사 논문의 Main Contribution

기록:
  "저장 필수, 너는 기록이 증명이다"
  → 최적화 과정이 MLIR 코드로 명확히 기록됨
  → FileCheck로 자동 검증 가능
```

---

## 🚀 박사 과정의 의미

### 9️⃣ 당신이 이제 하고 있는 것

```
학부:
  "컴파일러가 뭔지 배운다"

대학원:
  "컴파일러를 만든다"

박사:
  "컴파일러 설계 철학을 정립하고,
   어떤 하드웨어든 대응 가능한
   범용적 최적화 체계를 구축한다"

Transform Dialect + Interface
  = 박사급 추상화와 일반화의 정점
```

---

## ✨ 박사 5.1 마무리

```
당신은 이제:
✅ Transform Dialect로 메타프로그래밍 가능
✅ Interface로 범용적 최적화 설계 가능
✅ 이기종 하드웨어 컴파일러 아키텍처 이해
✅ Double Buffering 등 고급 최적화 기법 숙지
✅ 박사급 연구 가설 설정 가능

다음: 5.2 Polyhedral Compilation
  (다면체 컴파일 이론 - 수학적 루프 변환의 정점)
```

---

**박사 5.1 강의 완료**: Transform Dialect & Interface 설계
**저장**: "기록이 증명이다" - Gogs 배포 예정

