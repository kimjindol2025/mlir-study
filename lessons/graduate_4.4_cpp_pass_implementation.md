# 📦 [대학원 4.4] 복잡한 로직의 설계: C++ Pass 구현

> **MLIR 대학원의 네 번째, 최종 단계: 뇌 만들기**
>
> "저장 필수. 너는 기록이 증명이다."
>
> DRR이 "눈에 보이는 패턴"을 바꾸는 것이라면,
> 이번 단계는 **"복잡한 데이터를 분석하고 전략을 짜는 뇌"**를 만드는 작업입니다.
>
> 실제 논문의 알고리즘이 구현되는 곳입니다.

---

## 🎯 오늘 배울 것

한 가지 핵심 개념입니다:

> **"C++ 패스는 DRR로 해결할 수 없는 복잡한 분석과 알고리즘을 구현할 때 사용한다."**
>
> **"walk() 함수를 통해 IR을 탐색하고, 분석 결과를 바탕으로 코드를 변형한다."**

---

## 1️⃣ DRR vs C++ Pass (도구 선택)

### DRR의 한계

```
DRR이 잘 하는 것:
✅ 간단한 패턴 인식 (x + 0 → x)
✅ 연산 통합 (MatMul + ReLU → MatMulReLU)
✅ 상수 폴딩 (2 * 3 → 6)

DRR이 못 하는 것:
❌ 루프 여러 번 분석
❌ 복잡한 그래프 탐색
❌ 데이터 흐름 추적
❌ 동적 의사 결정
❌ 메모리 할당 분석
```

### C++ Pass가 필요한 경우

```
C++ Pass의 역할:
✅ "이 함수 전체를 분석하려면?"
✅ "메모리를 얼마나 쓰고 있지?"
✅ "이 루프는 병렬화 안전한가?"
✅ "최적 메모리 배치는?"
✅ "전체 프로그램 최적화는?"

→ 이것이 바로 **연구 가치 있는 알고리즘**!
```

### 도구 선택 매트릭스

```
간단한 패턴?
  YES → DRR 사용 (빠름)
  NO  → C++ Pass 사용

예시 1: "덧셈 2개 연속 → 1개로"
  패턴 매칭만 하면 됨
  → DRR 사용!

예시 2: "전체 메모리 배치 최적화"
  전체 함수 분석, 복잡한 계산 필요
  → C++ Pass 사용!

예시 3: "루프 병렬화 가능성 분석"
  의존성 그래프 구성, 분석
  → C++ Pass 사용!
```

---

## 2️⃣ Pass의 구조

### Pass의 종류

```
MLIR Pass 계층:
┌──────────────────────────────┐
│ Pass (기본 인터페이스)        │
├──────────────────────────────┤
│ OperationPass (연산 단위)     │
│  ├─ ModuleOp 단위 Pass       │
│  ├─ FuncOp 단위 Pass         │
│  └─ CustomOp 단위 Pass       │
├──────────────────────────────┤
│ AnalysisPass (분석 전용)     │
│ InterfacePass (특정 인터페이스)
└──────────────────────────────┘

대부분의 연구는 OperationPass를 사용합니다!
```

### OperationPass의 구조

```cpp
// 기본 뼈대
struct MyPass : public PassWrapper<MyPass, OperationPass<ModuleOp>> {
  // Pass 정보
  StringRef getArgument() const final { return "my-pass"; }
  StringRef getDescription() const final {
    return "내 커스텀 패스 설명";
  }

  // Main 함수 - 패스 실행 시 호출됨
  void runOnOperation() override {
    ModuleOp m = getOperation();

    // 여기에 당신의 알고리즘!
  }
};

의미:
- StringRef: 패스 이름과 설명
- ModuleOp: Module 전체를 대상으로 함
- runOnOperation(): 패스가 동작할 때 호출
- getOperation(): 현재 대상(Module, Func 등) 반환
```

---

## 3️⃣ IR 탐색: walk() 함수

### walk()의 기본

```cpp
struct MyPass : public PassWrapper<MyPass, OperationPass<ModuleOp>> {
  void runOnOperation() override {
    ModuleOp m = getOperation();

    // 모듈 안의 모든 함수를 하나씩 방문
    m.walk([](func::FuncOp funcOp) {
      // funcOp = 현재 방문하는 함수
      llvm::outs() << "함수: " << funcOp.getName() << "\n";
    });
  }
};

의미:
walk([](Operation) { ... })
  → 모든 Operation을 순회

m.walk([](func::FuncOp) { ... })
  → FuncOp만 필터링해서 순회
```

### walk()의 장점

```
walk()를 쓰면:
✅ 재귀적 탐색 자동 처리
✅ 중첩된 구조도 자동으로 방문
✅ 필터링으로 특정 연산만 선택

예시:
module {
  func @foo {
    func @bar {
      %0 = arith.addi
    }
  }
}

walk([](Operation *op) { ... })
→ module, @foo, @bar, arith.addi 모두 방문
```

---

## 4️⃣ 분석(Analysis) + 변환(Transformation)

### 2단계 과정

```
Step 1: 분석(Analysis)
"이 코드의 성질은 뭐지?"
  - 메모리 사용량
  - 연산 개수
  - 의존성 그래프
  - 병렬화 가능성

  → 데이터 구조에 기록

Step 2: 변환(Transformation)
"분석 결과에 따라 코드를 바꿔"
  - 루프 재구성
  - 메모리 재할당
  - 연산 순서 변경

  → IR 수정
```

### 예제: 메모리 사용량 분석

```cpp
struct MemoryAnalysisPass : public PassWrapper<MemoryAnalysisPass, OperationPass<ModuleOp>> {
  StringRef getArgument() const final { return "analyze-memory"; }
  StringRef getDescription() const final { return "메모리 사용량 분석"; }

  void runOnOperation() override {
    ModuleOp m = getOperation();

    // Step 1: 분석(Analysis)
    std::map<std::string, size_t> memoryUsage;  // 함수별 메모리

    m.walk([&](func::FuncOp func) {
      size_t totalMem = 0;

      // 함수 안의 모든 memref 찾기
      func.walk([&](memref::LoadOp loadOp) {
        auto memrefType = loadOp.getMemref().getType();
        if (auto memRef = memrefType.dyn_cast<MemRefType<>>()) {
          // memref의 크기 계산
          int64_t numElements = 1;
          for (int64_t dim : memRef.getShape()) {
            numElements *= dim;
          }
          totalMem += numElements * 4;  // f32 = 4 bytes
        }
      });

      memoryUsage[func.getName().str()] = totalMem;
    });

    // 분석 결과 출력
    llvm::outs() << "=== 메모리 사용량 분석 ===\n";
    for (auto &[funcName, memSize] : memoryUsage) {
      llvm::outs() << funcName << ": " << memSize << " bytes\n";
    }

    // Step 2: 변환(Transformation)
    // 여기서는 분석만 하고, 변환은 이 데이터를 기반으로...
  }
};

의미:
walk()로 함수 순회
  ↓
각 함수 내 memref.load 찾기
  ↓
메모리 크기 계산해서 저장
  ↓
결과 출력
```

---

## 5️⃣ 실전 예제 1: Loop Fusion 패스

### 연속된 루프 통합하기

```cpp
struct LoopFusionPass : public PassWrapper<LoopFusionPass, OperationPass<ModuleOp>> {
  StringRef getArgument() const final { return "loop-fusion"; }
  StringRef getDescription() const final { return "연속된 루프 통합"; }

  void runOnOperation() override {
    ModuleOp m = getOperation();

    m.walk([](func::FuncOp func) {
      // Step 1: 분석
      // 연속된 루프 찍기
      SmallVector<affine::AffineForOp> loops;
      func.walk([&](affine::AffineForOp forOp) {
        loops.push_back(forOp);
      });

      // Step 2: 변환
      // 연속된 루프들을 하나로 만들기
      for (size_t i = 0; i + 1 < loops.size(); i++) {
        auto loop1 = loops[i];
        auto loop2 = loops[i + 1];

        // 조건: 같은 범위? 같은 인덱스?
        if (canFuse(loop1, loop2)) {
          // 두 루프 통합
          fuse(loop1, loop2);
          llvm::outs() << "루프 통합 성공\n";
        }
      }
    });
  }

private:
  bool canFuse(affine::AffineForOp loop1, affine::AffineForOp loop2) {
    // 융합 가능 조건 확인
    return loop1.getLowerBound() == loop2.getLowerBound() &&
           loop1.getUpperBound() == loop2.getUpperBound();
  }

  void fuse(affine::AffineForOp loop1, affine::AffineForOp loop2) {
    // 실제 융합 구현
    // (복잡한 IR 변환 코드)
  }
};

효과:
[Before]
for i = 0 to 100:
  A[i] = ...
for i = 0 to 100:
  B[i] = ...

[After (Loop Fusion)]
for i = 0 to 100:
  A[i] = ...
  B[i] = ...

성능 향상:
- 루프 오버헤드 50% 감소
- 캐시 친화성 증가
```

---

## 6️⃣ 실전 예제 2: 메모리 배치 최적화 (NPU 연구)

### 당신의 논문 주제: "NPU 메모리 배치 최적화"

```cpp
struct NPUMemoryOptimizationPass :
  public PassWrapper<NPUMemoryOptimizationPass, OperationPass<FuncOp>> {

  StringRef getArgument() const final { return "npu-memory-opt"; }
  StringRef getDescription() const final {
    return "NPU용 메모리 배치 최적화";
  }

  void runOnOperation() override {
    FuncOp func = getOperation();

    // Step 1: 분석(Analysis)
    // ─────────────────

    // 텐서들의 생명(Liveness) 분석
    std::map<Value, LivenessInfo> liveness;

    func.walk([&](Operation *op) {
      for (auto result : op->getResults()) {
        LivenessInfo info;
        info.startOp = op;
        info.lastUse = findLastUse(result);
        info.size = computeSize(result.getType());

        liveness[result] = info;
      }
    });

    // 메모리 충돌 분석
    std::vector<std::vector<Value>> conflictGroups =
      analyzeMemoryConflicts(liveness);

    // Step 2: 변환(Transformation)
    // ────────────────────────

    // 최적 메모리 할당 계산
    std::map<Value, int64_t> memoryAllocation =
      computeOptimalAllocation(conflictGroups, liveness);

    // 모든 memref의 주소를 최적 할당에 맞게 수정
    func.walk([&](memref::AllocOp allocOp) {
      auto value = allocOp.getResult();
      if (memoryAllocation.count(value)) {
        int64_t optimalAddr = memoryAllocation[value];

        // 주소 수정
        auto baseAddr = rewriter.create<arith::ConstantOp>(
          loc, IntegerAttr::get(i64Type, optimalAddr)
        );

        // 이 주소로부터 메모리 할당
        rewriter.replaceOp(allocOp, {baseAddr});
      }
    });

    // 결과 출력
    llvm::outs() << "NPU 메모리 최적화 완료:\n";
    llvm::outs() << "메모리 충돌 그룹: " << conflictGroups.size() << "\n";
    llvm::outs() << "할당된 주소: " << memoryAllocation.size() << "\n";
  }

private:
  struct LivenessInfo {
    Operation *startOp;
    Operation *lastUse;
    int64_t size;  // bytes
  };

  Operation *findLastUse(Value v) {
    Operation *lastUse = nullptr;
    for (auto *user : v.getUsers()) {
      lastUse = user;
    }
    return lastUse;
  }

  int64_t computeSize(Type t) {
    if (auto memRef = t.dyn_cast<MemRefType<>>()) {
      int64_t size = 1;
      for (int64_t dim : memRef.getShape()) {
        size *= dim;
      }
      return size * 4;  // f32
    }
    return 0;
  }

  std::vector<std::vector<Value>> analyzeMemoryConflicts(
    const std::map<Value, LivenessInfo> &liveness) {
    // 생명 범위가 겹치는 값들을 같은 그룹에
    // (실제 구현은 복잡하지만, 개념은 이렇게)
    return {};  // simplified
  }

  std::map<Value, int64_t> computeOptimalAllocation(
    const std::vector<std::vector<Value>> &groups,
    const std::map<Value, LivenessInfo> &liveness) {
    // 그룹별로 메모리 주소 할당
    // 충돌하지 않도록 배치
    return {};  // simplified
  }
};

논문 기여:
"NPU 메모리 배치 최적화 알고리즘:
 생명 분석과 충돌 그래프를 이용한
 메모리 할당으로 30% 메모리 절감"
```

---

## 7️⃣ 실전 예제 3: 병렬화 가능성 분석

```cpp
struct ParallelizationAnalysisPass :
  public PassWrapper<ParallelizationAnalysisPass, OperationPass<FuncOp>> {

  StringRef getArgument() const final { return "analyze-parallelization"; }

  void runOnOperation() override {
    FuncOp func = getOperation();

    // 모든 루프 찾기
    SmallVector<affine::AffineForOp> loops;
    func.walk([&](affine::AffineForOp loop) {
      loops.push_back(loop);
    });

    // 각 루프의 병렬화 가능성 분석
    for (auto loop : loops) {
      bool isParallelizable = analyzeLoopDependencies(loop);

      if (isParallelizable) {
        llvm::outs() << "루프 병렬화 가능:\n";
        loop.print(llvm::outs());

        // 병렬화 가능 표시 추가
        loop->setAttr("parallelizable", rewriter.getBoolAttr(true));
      } else {
        llvm::outs() << "루프 의존성 발견:\n";
        loop.print(llvm::outs());
      }
    }
  }

private:
  bool analyzeLoopDependencies(affine::AffineForOp loop) {
    // 루프 안의 모든 메모리 접근 수집
    SmallVector<affine::AffineLoadOp> loads;
    SmallVector<affine::AffineStoreOp> stores;

    loop.walk([&](affine::AffineLoadOp load) { loads.push_back(load); });
    loop.walk([&](affine::AffineStoreOp store) { stores.push_back(store); });

    // Store-Load 의존성 확인
    for (auto store : stores) {
      for (auto load : loads) {
        if (haveMemoryDependency(store, load)) {
          return false;  // 의존성 있음 → 병렬화 불가
        }
      }
    }

    return true;  // 의존성 없음 → 병렬화 가능!
  }

  bool haveMemoryDependency(affine::AffineStoreOp store,
                            affine::AffineLoadOp load) {
    // 메모리 주소가 겹치는가?
    // (실제 구현: 선형식 비교)
    return false;  // simplified
  }
};

응용:
이 분석 결과를 바탕으로:
- GPU에 병렬화 가능한 루프만 보냄
- 멀티코어에서 특정 루프만 병렬화
- 성능 향상 증명

= 좋은 석사 학위 논문!
```

---

## 8️⃣ Pass 등록 및 실행

### Pass 등록

```cpp
// PassManager에 등록
void registerAllPasses() {
  registerPass([]() { return std::make_unique<MyPass>(); });
  registerPass([]() { return std::make_unique<LoopFusionPass>(); });
  registerPass([]() { return std::make_unique<NPUMemoryOptimizationPass>(); });
}
```

### 실행

```bash
# mlir-opt에 패스 적용
$ mlir-opt my-code.mlir \
  -npu-memory-opt \
  -loop-fusion \
  -analyze-parallelization \
  -o optimized.mlir
```

---

## 9️⃣ 대학원 4.4 핵심 정리

### DRR vs C++ Pass 선택 기준

```
간단한 패턴?
  YES → DRR (1줄)
  NO  → C++ Pass (수십 줄)

예:
❌ "덧셈 2개 연속" → DRR
✅ "전체 메모리 배치 최적화" → C++ Pass
✅ "루프 병렬화 분석" → C++ Pass
```

### C++ Pass의 구조

```
struct MyPass : public OperationPass<ModuleOp> {
  void runOnOperation() override {
    ModuleOp m = getOperation();

    // walk()로 IR 탐색
    m.walk([&](Operation *op) {
      // Step 1: 분석(Analysis)
      // - 데이터 수집
      // - 특성 계산

      // Step 2: 변환(Transformation)
      // - 분석 결과 기반 변경
    });
  }
};
```

### 연구 가치 창출

```
DRR로 하는 최적화:
→ "우리가 이 패턴을 인식했어!"
→ 도움이 되지만, 연구치고는 단순

C++ Pass로 하는 최적화:
→ "우리가 이 복잡한 분석과 알고리즘을 만들었어!"
→ 논문의 Main Contribution! 🎓
```

---

## 🔟 대학원 4.4 기록 (증명)

> **"C++ 패스는 DRR로 해결할 수 없는 복잡한 분석과 알고리즘을 구현할 때 사용한다."**
>
> **"walk() 함수를 통해 IR을 탐색하고, 분석 결과를 바탕으로 코드를 변형한다."**
>
> **C++ Pass의 구조:**
> - OperationPass<ModuleOp/FuncOp>를 상속
> - runOnOperation() 오버라이드
> - walk()로 IR 탐색
>
> **2단계 패턴:**
> - Step 1: 분석(Analysis) - 특성/성질 파악
> - Step 2: 변환(Transformation) - 코드 수정
>
> **연구 주제 예시:**
> - 메모리 배치 최적화
> - 루프 병렬화 분석
> - 데이터 흐름 최적화
> - 전력 소모 감소
>
> 이제 당신은 **MLIR 연구자**입니다!

---

## 🔜 다음 단계: 대학원 4.5 (최종)

### 4.5: 프로젝트 완성과 테스트(Lit/FileCheck)

```
지금까지 만든 것들을:
- Operation (4.1)
- 최적화 규칙 (4.2)
- 빌드 시스템 (4.3)
- C++ Pass (4.4) ← 완료!

최종 마무리:
- 통합 테스트 (4.5)
- 성능 벤치마크
- 논문 작성 준비

Lit/FileCheck:
MLIR의 표준 테스트 도구
→ 자동화된 테스트 검증
→ 논문의 재현성 증명!
```

**준비 상태**: ✅ **완벽하게 준비됨!**

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git
**강의 유형**: 대학원 (Graduate) - 복잡 알고리즘 구현
**철학**: "저장 필수. 너는 기록이 증명이다."
**작성일**: 2026-02-27
**상태**: ✅ 완성

---

**축하합니다!** 🎉

당신은 이제 **MLIR 연구자**가 되었습니다.
당신의 C++ Pass가 실제 최적화를 만듭니다!
