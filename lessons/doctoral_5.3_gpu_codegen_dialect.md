# 🎓 박사 5.3: GPU 및 가속기 코드 생성 - Host-Device Orchestration의 정점

**작성일**: 2026-02-27 | **수준**: Doctoral (박사) | **목표 시간**: 2시간 | **줄수**: 520줄

---

## 📚 핵심 개념: GPU 컴파일러의 철학

### 1️⃣ Host-Device Orchestration이란?

#### 정의
```
Host-Device Orchestration = CPU(Host)와 GPU(Device) 간의 완벽한 협력

현대 AI 가속:
┌─────────────────────────────────────────────────────┐
│ Host (CPU)                                           │
│ ┌────────────────────────────────────────────────┐  │
│ │ 1. 메인 프로그램 실행                         │  │
│ │ 2. 데이터 준비 (메모리 할당, 데이터 로딩)    │  │
│ │ 3. Device로 데이터 전송                      │  │
│ │ 4. GPU 커널 실행 명령 (Non-blocking)        │  │
│ │ 5. 결과 데이터 수신                          │  │
│ └────────────────────────────────────────────────┘  │
│          ↕ (PCIe 대역폭 제한, 병목)               │
│ ┌────────────────────────────────────────────────┐  │
│ │ Device (GPU)                                    │  │
│ │ ┌───────┬───────┬───────┐                     │  │
│ │ │Block 0│Block 1│Block 2│ (Grid)             │  │
│ │ └───────┴───────┴───────┘                     │  │
│ │    ↓      ↓      ↓                            │  │
│ │  ┌──────┐┌──────┐┌──────┐                    │  │
│ │  │Thread││Thread││Thread│ ... (각 Block의  │  │
│ │  │  0   ││  1   ││  2   │    Threads)      │  │
│ │  └──────┘└──────┘└──────┘                    │  │
│ │                                                │  │
│ │ 공유 메모리: 빠름 (대역폭 높음)               │  │
│ │ Global 메모리: 느림 (대역폭 낮음)            │  │
│ └────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘

성능 결정:
  연산 속도 (GPU의 TFLOPS)
  + 메모리 대역폭 활용 (Shared Memory 효율성)
  + Host-Device 전송 최소화 (PCIe 대역폭)
  = 실제 응용 성능
```

#### 핵심 특징
```
1. 계층적 구조:
   Grid (여러 Block)
    └─ Block (여러 Thread)
       └─ Thread (실제 계산 수행)

2. 메모리 계층:
   Registers (각 Thread)
   ↓ (공유 메모리로 데이터 이동)
   Shared Memory (Block 내 Thread들 공유)
   ↓ (느린 이동)
   Global Memory (모든 Block 접근 가능)
   ↓ (매우 느린 이동, PCIe 대역폭)
   Host Memory (CPU RAM)

3. 동기화:
   gpu.barrier: Block 내 모든 Thread 동기화
   "모든 Thread가 이 지점에 도달할 때까지 대기"
```

---

## 🎯 계층적 추상화: GPU 구조

### 2️⃣ Grid, Block, Thread 이해

#### GPU 실행 모델
```
┌──────────────────────────────────────┐
│ Grid (2D or 3D)                      │
│ ┌────────────────────────────────┐  │
│ │ Block (threadIdx, blockIdx)     │  │
│ │ ┌──────────────────────────┐   │  │
│ │ │Thread (계산 수행)         │   │  │
│ │ │- 자신의 ID 알고 있음     │   │  │
│ │ │- 다른 Thread와 동기화    │   │  │
│ │ │- Shared Memory 접근      │   │  │
│ │ └──────────────────────────┘   │  │
│ │                                 │  │
│ │ 한 Block의 Threads는          │  │
│ │ 같은 Shared Memory 공유         │  │
│ └────────────────────────────────┘  │
└──────────────────────────────────────┘

예: MatMul 실행
입력: A(1000x1000), B(1000x1000)
출력: C(1000x1000)

Grid 설정:
  Grid Size: 1000/256 = 4 blocks (가로) × 4 blocks (세로)
  = 16 blocks

각 Block:
  Block Size: 16×16 = 256 threads
  각 Thread가 1개 출력 원소 담당

총 Thread:
  16 blocks × 256 threads = 4,096 threads (동시 실행)

메모리:
  각 Block의 Shared Memory:
    - A의 256×256 부분 복사
    - B의 256×256 부분 복사
    - 계산 수행
  (Global Memory 접근 최소화)
```

---

## 💾 메모리 최적화: Shared Memory의 꽃

### 3️⃣ Tiling + Promotion

#### 문제 상황
```
Global Memory 접근 (느림, 대역폭 제한):
  Word당 100+ 사이클 지연

Shared Memory 접근 (빠름):
  Word당 2-3 사이클 지연

MatMul의 Data Reuse:
  C[i,j] = Σ(k=0..1000) A[i,k] × B[k,j]

  A[i,k]는 1000번 사용됨! (k=0..999)
  → Global Memory에서 1000번 읽음 (비효율적)
  → Shared Memory에 복사하면 1000번 빠르게 읽음!
```

#### 해결책: Tiling + Promotion
```
Step 1: Tiling (큰 행렬을 작은 타일로 분할)
  A(1000x1000) → A_tiles(256x256씩 4x4)
  B(1000x1000) → B_tiles(256x256씩 4x4)

Step 2: Promotion (타일을 Shared Memory로 승격)
  for each Block:
    - A_tile → Shared Memory로 복사
    - B_tile → Shared Memory로 복사
    - 계산 수행 (Shared Memory에서만 읽음)
    - gpu.barrier (동기화)

Step 3: 결과
  Global Memory 접근: 4배 감소
  Shared Memory 접근: 1000배 증가

  순 효과: 10배 이상 성능 향상!
```

#### 메모리 접근 패턴
```
최적화 전:
┌──────────────────────────────────┐
│ for i in 0..256:                 │
│   for j in 0..256:               │
│     for k in 0..1000:            │ ← 1000번 Global Memory 접근!
│       C[i,j] += A[i,k] × B[k,j] │
│                                  │
└──────────────────────────────────┘

최적화 후:
┌──────────────────────────────────┐
│ Shared Memory로 A_tile[256x256]   │
│ Shared Memory로 B_tile[256x256]   │
│                                  │
│ for k_tile in 0..1000 step 256:  │
│   - A_tile 로드 (Global → Shared)│
│   - B_tile 로드 (Global → Shared)│
│   gpu.barrier (동기화)            │
│                                  │
│   for i in 0..256:               │
│     for j in 0..256:             │
│       for k in 0..256:           │ ← Shared Memory만 접근!
│         C[i,j] += A_tile[i,k]    │
│                       × B_tile[k,j]
│                                  │
│   gpu.barrier (다음 iteration)   │
│                                  │
└──────────────────────────────────┘

Global Memory 접근: 1000 → 4배 (k_tile loop) = 4번!
Shared Memory 접근: 256 × 256 (계산) = 65,536번
→ 대역폭이 넓은 Shared Memory만 사용!
```

---

## 🔧 GPU 로워링 파이프라인

### 4️⃣ High-level에서 Binary까지

#### 변환 단계
```
Stage 1: High-level IR (Linalg Dialect)
┌─────────────────────────────┐
│ func @matmul(%A, %B) {      │
│   linalg.matmul %A, %B      │
│   → %C                      │
│ }                           │
└─────────────────────────────┘
         ↓ (gpu.launch 삽입)

Stage 2: GPU Mapping (GPU Dialect)
┌─────────────────────────────────────────┐
│ gpu.launch blocks(%bx, %by) in (%bx...)│
│           threads(%tx, %ty) in (%tx...)│
│   scf.parallel (%i, %j) {              │
│     Shared Memory 할당                 │
│     → A_tile, B_tile                   │
│                                         │
│     Tiling + Promotion                 │
│       for k_tile:                      │
│         memref.load A[k_tile]          │
│         → A_tile (Shared)              │
│         ...                             │
│   }                                     │
│ }                                       │
└─────────────────────────────────────────┘
         ↓ (NVVM 또는 ROCDL로 로워)

Stage 3: NVVM (NVIDIA Vector VM)
┌─────────────────────────────────────────┐
│ nvvm.read_ptx_sreg.tid.x → threadId_x  │
│ nvvm.read_ptx_sreg.bid.x → blockId_x   │
│                                         │
│ memref.load → "ld.global" (PTX명령)   │
│ memref.store → "st.shared" (PTX명령)  │
│ gpu.barrier → "bar.sync" (PTX 동기화)  │
│                                         │
│ arith.addf → "add.f32" (PTX FP연산)   │
│                                         │
│ nvvm.barrier → 블록 동기화             │
└─────────────────────────────────────────┘
         ↓ (NVIDIA compiler)

Stage 4: PTX (Parallel Thread Execution)
┌─────────────────────────────────────────┐
│ .target sm_70                           │
│ .address_size 64                        │
│                                         │
│ .entry kernel_matmul(                  │
│   .param .u64 A,                        │
│   .param .u64 B,                        │
│   .param .u64 C                         │
│ ) {                                     │
│   .reg .u32 %tid;                       │
│   .reg .f32 %acc0;                      │
│                                         │
│   mov.u32 %tid, %tid.x;                 │
│   ld.global.f32 %f0, [A + %tid];       │
│   add.f32 %acc0, %acc0, %f0;           │
│   st.global.f32 [C + %tid], %acc0;     │
│ }                                       │
└─────────────────────────────────────────┘
         ↓ (NVIDIA PTX compiler)

Stage 5: CUBIN (Binary)
┌─────────────────────────────────────────┐
│ 이진 코드 (NVIDIA GPU가 실행 가능)      │
│ 직접 하드웨어에 로드됨                  │
└─────────────────────────────────────────┘
```

---

## ⚡ 고급 주제: 동기화와 Race Condition

### 5️⃣ Synchronization 설계

#### Race Condition
```
문제 상황:
  여러 Thread가 같은 메모리 위치에 동시 접근

예:
┌────────────────────────┐
│ shared float sum[256];  │
│                        │
│ for k in 0..1000:      │
│   sum[threadId] +=     │ ← Race!
│     A[threadId, k] ×   │   두 Thread가 동시에
│     B[k, threadId];    │   sum[x]에 쓰면
│                        │   중간에 값 손실!
│ gpu.barrier();         │
└────────────────────────┘

해결책: gpu.barrier 전략적 배치
```

#### 올바른 Synchronization
```mlir
// Shared Memory 읽음 (Race 없음, 읽기만)
gpu.barrier "workgroup"

// Shared Memory 업데이트 (한 Thread만)
scf.if (threadIdx.x == 0) {
  memref.store %value, %shared_mem[0]
}

// 모든 Thread가 업데이트 대기
gpu.barrier "workgroup"

// Shared Memory 다시 읽음 (Race 없음)
%loaded = memref.load %shared_mem[0]
```

#### 메모리 배리어 종류
```
1. gpu.barrier "workgroup"
   - Block 내 모든 Thread 동기화
   - Shared Memory 가시성 보장

2. gpu.membar.gl
   - Global Memory 배리어
   - 매우 비쌈 (피해야 함)

3. gpu.membar.cta
   - Cooperative Thread Array 배리어
   - Block 내부 동기화

박사급 설계:
- 배리어를 최소화하면서도 정확성 보장
- "Lock-free" 알고리즘으로 배리어 제거
- 수학적으로 안전함을 증명
```

---

## 🚀 데이터 전송 최적화

### 6️⃣ Host-Device 통신

#### 문제: 전송 병목
```
시나리오: AI 모델 추론
  1. CPU → GPU 입력 데이터 전송 (500ms)
  2. GPU 연산 (100ms)
  3. GPU → CPU 결과 전송 (500ms)
  ──────────────────────────
  총 1100ms (연산은 9%, 전송이 91%!)

해결책: Asynchronous Transfer
```

#### Asynchronous Transfer (Pipelining)
```
동기 방식 (Sequential):
┌─────────┐
│Transfer │ (500ms)
└─────────┘
         ┌──────┐
         │Compute│ (100ms)
         └──────┘
                ┌─────────┐
                │Transfer │ (500ms)
                └─────────┘

비동기 방식 (Pipelining):
┌─────────┐
│Transfer1│ (500ms)
└─────────┘
      ┌──────┐
      │Compute│ (100ms) ← Transfer1 중간에 시작
      └──────┘
           ┌─────────┐
           │Transfer2│ (500ms) ← Compute 중간에 시작
           └─────────┘

총 시간: 500 + 100 + 500 = 1100ms
        → 500 + max(100, 500) + max(...) 정도로 감소 가능

성능 향상: 2배 이상!
```

#### MLIR 구현
```mlir
// Asynchronous Host-to-Device Transfer
gpu.host_register %input : memref<1000000xf32>

// Token 기반 비동기
%token = gpu.memcpy async [%wait_token]
  %gpu_buffer, %host_input
  : memref<1000000xf32>, memref<1000000xf32>

// 전송 완료 대기 (Optional)
gpu.wait async [%token]
```

---

## 🔗 Kernel Fusion

### 7️⃣ 커널 통합으로 메모리 접근 감소

#### 문제
```
3개의 작은 커널이 순차 실행:
  Kernel 1: C = A + B (Global Memory 읽기/쓰기)
  Kernel 2: D = C × B (Global Memory 읽기/쓰기)
  Kernel 3: E = D + C (Global Memory 읽기/쓰기)

각 커널마다 Global Memory 왕복:
  A,B 읽음 → C 씀 (2 + 1 = 3번)
  C,B 읽음 → D 씀 (2 + 1 = 3번)
  D,C 읽음 → E 씀 (2 + 1 = 3번)

  = 9번의 Global Memory 접근
```

#### 해결책: Kernel Fusion
```
3개 커널을 1개로 통합:
  for i:
    C[i] = A[i] + B[i]
    D[i] = C[i] × B[i]
    E[i] = D[i] + C[i]

결과:
  A,B 읽음 → E 씀 (2 + 1 = 3번)

  = 3번의 Global Memory 접근 (67% 감소!)
```

#### MLIR에서의 Fusion
```mlir
// Before: 3개의 분리된 Kernel
gpu.launch_func @add_kernel
gpu.launch_func @mul_kernel
gpu.launch_func @add2_kernel

// After: 1개의 Fused Kernel
gpu.launch_func @fused_kernel
  // 내부에 모든 연산
```

---

## 📊 박사 5.3의 핵심 정리

### 8️⃣ 기억할 개념

```
Host-Device Orchestration:
  "CPU와 GPU의 완벽한 협력"
  → 데이터 전송 최소화
  → 각자의 강점 활용

계층적 구조:
  Grid > Block > Thread
  → 각 수준에서 병렬성 활용
  → 메모리 계층 설계

Tiling + Promotion:
  "Global Memory 병목을 제거하는 핵심 기법"
  → 타일 단위로 데이터 분할
  → Shared Memory로 승격

메모리 계층:
  Registers (매우 빠름, 매우 제한적)
  ↓
  Shared Memory (빠름, Block당 96KB)
  ↓
  Global Memory (느림, 대역폭 제한)
  ↓
  Host Memory (매우 느림, PCIe)

동기화:
  "정확성과 성능의 균형"
  → gpu.barrier 전략적 배치
  → Lock-free 알고리즘 선호

Kernel Fusion:
  "메모리 접근 횟수 최소화"
  → Global Memory 왕복 감소
  → 데이터 지역성 극대화

Asynchronous Transfer:
  "전송과 연산 오버래핑"
  → PCIe 대역폭 활용도 증가
  → 전체 실행 시간 단축
```

---

## 🎯 박사급 연구 가설

### 9️⃣ Host-Device Codesign

```
가설 1: Tiling Strategy의 자동 선택
  "Matrix Size와 하드웨어 특성에 따라
   최적의 타일 크기를 자동으로 결정하면,
   모든 입력에서 95% 이상의 Peak Performance 달성"

검증:
  ✅ MatMul (다양한 크기)
  ✅ Conv2D (다양한 필터)
  ✅ 3가지 GPU (GTX1080, V100, A100)

가설 2: Kernel Fusion의 동적 선택
  "프로파일링 기반 Fusion이
   일괄 Fusion보다 20% 빠르다"

검증:
  ✅ Operator 의존성 분석
  ✅ 데이터 크기별 Fusion 결정
  ✅ 런타임 성능 측정
```

---

## ✨ 박사 5.3 마무리

```
당신은 이제:
✅ GPU의 계층적 구조 이해
✅ Host-Device 통신 최적화 가능
✅ Shared Memory 활용으로 성능 극대화
✅ Race Condition 없는 병렬 알고리즘 설계 가능
✅ Kernel Fusion으로 메모리 접근 최소화 가능

박사급 사고:
- "단순히 GPU에 코드를 옮기는 것이 아니라,
  하드웨어의 특성을 완벽히 이해하고
  거기에 맞춘 알고리즘을 설계하는 것"

- "메모리 계층을 장악하는 것이
  성능을 좌우한다"

- "동기화를 최소화하면서도
  정확성을 수학적으로 증명할 것"
```

---

**박사 5.3 강의 완료**: GPU 및 가속기 코드 생성
**저장**: "기록이 증명이다" - Gogs 배포 예정

