# 📦 [대학 3.5] 설계도의 완성: LLVM IR로의 최종 변환

> **MLIR의 대학 다섯 번째, 마지막 단계: 기계의 언어로의 진화**
>
> "저장 필수. 너는 기록이 증명이다."
>
> 지금까지 우리는 추상적인 설계도를 그렸습니다.
> 이제 그 설계도를 컴퓨터 CPU가 실제로 실행할 수 있는
> **'기계어' 직전 단계인 LLVM IR**로 바꿀 차례입니다.
>
> 이 과정이 끝나야 비로소 프로그램이 "살아 움직이게" 됩니다.

---

## 🎯 오늘 배울 것

한 가지 핵심 개념입니다:

> **"MLIR은 최종적으로 LLVM IR로 번역되어 실제 하드웨어에서 실행된다."**
>
> **"한번 내려가면(Lowering) 정보를 다시 되돌리기 어려우므로, 높은 단계에서 최적화를 끝내는 것이 유리하다."**

---

## 1️⃣ 왜 LLVM IR로 가야 하나?

### 문제: 세상에는 수많은 CPU들이 있습니다

```
CPU 종류:
- Intel x86-64 (데스크톱, 서버)
- AMD x86-64 (데스크톱, 서버)
- ARM (모바일, 임베디드)
- Apple Silicon (M1, M2, M3...)
- RISC-V (개발 중인 미래 CPU)
- PowerPC (고성능 컴퓨팅)

문제: 이 모든 기계의 고유한 언어를 우리가 다 알아야 할까?
→ 아니요! LLVM에게 맡깁시다!
```

### 해결책: LLVM IR (Intermediate Representation)

```
우리가 할 일:
MLIR → LLVM IR (표준 중간 언어로 번역)

LLVM이 할 일:
LLVM IR → Intel 기계어
LLVM IR → ARM 기계어
LLVM IR → Apple Silicon 기계어
...

→ 한 번의 컴파일로 모든 CPU를 지원!
```

### 비유: 영어의 힘

```
시나리오 1 (우리가 직접 기계어로):
한국어 → 영어
한국어 → 중국어
한국어 → 일본어
한국어 → 독일어
... (매우 복잡)

시나리오 2 (LLVM IR처럼):
한국어 → 영어 (표준 중간 언어)
         ↓
   영어로 된 책이 완성됨
         ↓
   각 나라가 알아서 번역
   영어 → 중국어
   영어 → 일본어
   영어 → 독일어
   ... (훨씬 효율적)
```

---

## 2️⃣ Lowering Pipeline: 추상에서 구체로

### 변환의 4단계

```
┌─────────────────────────────────────────────────┐
│ Stage 1: High-level (추상적, 수학적)            │
│ (Tosa, Linalg, Affine)                          │
│ "이 행렬들을 곱해줘."                            │
│ %res = linalg.matmul %A, %B                    │
└──────────────┬──────────────────────────────────┘
               ↓ (lowering pass)

┌─────────────────────────────────────────────────┐
│ Stage 2: Mid-level (반구체적, 루프 기반)        │
│ (Affine, SCF - Structured Control Flow)         │
│ "루프를 돌려서 곱셈을 수행해."                   │
│ affine.for %i = 0 to N {                       │
│   affine.for %j = 0 to M {                     │
│     ... memref.load, arith.mulf, ...           │
│   }                                             │
│ }                                               │
└──────────────┬──────────────────────────────────┘
               ↓ (lowering pass)

┌─────────────────────────────────────────────────┐
│ Stage 3: Low-level (구체적, 포인터 연산)         │
│ (LLVM Dialect, LLVM operations)                 │
│ "이 주소의 포인터를 가져와서 더하고 저장해."    │
│ %ptr = llvm.inttoptr %addr : i64 to !llvm.ptr  │
│ %val = llvm.load %ptr : f32                    │
│ %sum = llvm.fadd %val, %rhs : f32              │
│ llvm.store %sum, %ptr : f32                    │
└──────────────┬──────────────────────────────────┘
               ↓ (llvm-translate)

┌─────────────────────────────────────────────────┐
│ Stage 4: Final (기계어 직전, 표준 중간언어)     │
│ (LLVM IR - 모든 CPU가 이해 가능)                │
│ %0 = load float, ptr %ptr, align 4             │
│ %1 = fadd float %0, %1                         │
│ store float %1, ptr %ptr, align 4              │
│ ...                                             │
└─────────────────────────────────────────────────┘
               ↓ (backend compiler)

           실제 기계어 생성
        (CPU마다 최적화)
```

### 각 단계의 특징

| 단계 | 수준 | 특징 | 최적화 |
|------|------|------|--------|
| 1 | High-level | 추상적, 수학적 | ✅ 병렬화, 알고리즘 |
| 2 | Mid-level | 루프, 조건문 | ✅ 틸링, 벡터화 |
| 3 | Low-level | 메모리, 포인터 | ✅ 레지스터 할당 |
| 4 | Final | LLVM IR | ✅ CPU별 최적화 |

---

## 3️⃣ 실제 변환 예제

### 예제 1: 단순 덧셈

#### Stage 1: High-level MLIR

```mlir
func.func @add_simple(%arg0: f32, %arg1: f32) -> f32 {
  %res = arith.addf %arg0, %arg1 : f32
  func.return %res : f32
}
```

**특징**:
- Dialect: `arith` (산술)
- 형식: `arith.addf`
- MLIR 문법

#### Stage 2: Mid-level (변화 없음, 이미 충분히 구체적)

```mlir
func.func @add_simple(%arg0: f32, %arg1: f32) -> f32 {
  %res = arith.addf %arg0, %arg1 : f32
  func.return %res : f32
}
```

#### Stage 3: Low-level LLVM Dialect

```mlir
func.func @add_simple(%arg0: f32, %arg1: f32) -> f32 {
  %0 = llvm.fadd %arg0, %arg1 : f32
  func.return %0 : f32
}
```

**변화**:
- `arith.addf` → `llvm.fadd`
- Dialect가 LLVM으로 변경

#### Stage 4: Final LLVM IR

```llvm
define float @add_simple(float %arg0, float %arg1) {
  %0 = fadd float %arg0, %arg1
  ret float %0
}
```

**최종 변화**:
- MLIR 문법 완전 소거
- LLVM IR 문법 적용
- 함수 선언 방식 변경
- 이제 컴파일러 백엔드가 바로 이해 가능

### 예제 2: 메모리 접근

#### Stage 1: High-level (Tensor)

```mlir
func.func @load_tensor(%arg0: tensor<10xf32>, %idx: index) -> f32 {
  %val = tensor.extract %arg0[%idx] : tensor<10xf32> -> f32
  func.return %val : f32
}
```

#### Stage 2: Mid-level (MemRef + 루프)

```mlir
func.func @load_memref(%arg0: memref<10xf32>, %idx: index) -> f32 {
  %val = memref.load %arg0[%idx] : memref<10xf32>
  func.return %val : f32
}
```

**변화**:
- `tensor.extract` → `memref.load`
- 추상 텐서 → 실제 메모리 참조

#### Stage 3: Low-level (포인터 연산)

```mlir
func.func @load_llvm(%base: i64, %idx: i64) -> f32 {
  %ptr = llvm.inttoptr %base : i64 to !llvm.ptr<f32>
  %offset_ptr = llvm.getelementptr %ptr[%idx] : (!llvm.ptr<f32>, i64) -> !llvm.ptr<f32>
  %val = llvm.load %offset_ptr : !llvm.ptr<f32> -> f32
  func.return %val : f32
}
```

**변화**:
- 메모리 추상화 사라짐
- 실제 포인터 연산
- GEP (Get Element Pointer) 같은 저수준 연산 등장

#### Stage 4: Final LLVM IR

```llvm
define float @load_llvm(i64 %base, i64 %idx) {
  %1 = inttoptr i64 %base to float*
  %2 = getelementptr float, float* %1, i64 %idx
  %3 = load float, float* %2, align 4
  ret float %3
}
```

**최종 변화**:
- C 포인터 문법과 유사
- CPU가 바로 이해할 수 있는 연산들

### 예제 3: 루프 변환

#### Stage 1: High-level (추상 행렬 곱)

```mlir
func.func @matmul(%A: tensor<4x4xf32>, %B: tensor<4x4xf32>) -> tensor<4x4xf32> {
  %C = linalg.matmul %A, %B : (tensor<4x4xf32>, tensor<4x4xf32>) -> tensor<4x4xf32>
  func.return %C : tensor<4x4xf32>
}
```

**라인 수**: 3줄
**개념**: "A와 B를 곱해줘" (단순 명령)

#### Stage 2: Mid-level (루프 구현)

```mlir
func.func @matmul_loop(%A: memref<4x4xf32>, %B: memref<4x4xf32>, %C: memref<4x4xf32>) {
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
  func.return
}
```

**라인 수**: 16줄
**개념**: 실제 루프로 구현

#### Stage 3: Low-level (포인터 기반)

```mlir
func.func @matmul_llvm(%A: i64, %B: i64, %C: i64) {
  %stride_A = arith.constant 16 : i64  // 4 float * 4 bytes
  %stride_B = arith.constant 16 : i64
  %stride_C = arith.constant 16 : i64

  affine.for %i = 0 to 4 {
    affine.for %j = 0 to 4 {
      affine.for %k = 0 to 4 {
        %idx_A = arith.addi %i, %k : index // 실제 인덱싱 계산
        %ptr_a = llvm.inttoptr %A : i64 to !llvm.ptr<f32>
        // ... 포인터 계산 및 로드/스토어
      }
    }
  }
  func.return
}
```

**변화**:
- 메모리 주소 직접 계산
- 포인터 연산 등장

#### Stage 4: Final LLVM IR

```llvm
define void @matmul_llvm(i64 %A, i64 %B, i64 %C) {
  br label %bb1

bb1:
  %i = phi i64 [0, %0], [%i_next, %bb2]
  %cond1 = icmp slt i64 %i, 4
  br i1 %cond1, label %bb2, label %exit

bb2:
  ; j 루프 시작
  br label %bb3

bb3:
  %j = phi i64 [0, %bb2], [%j_next, %bb4]
  %cond2 = icmp slt i64 %j, 4
  br i1 %cond2, label %bb4, label %next_i

bb4:
  ; k 루프 시작 (자세히 생략)
  %a_ptr = inttoptr i64 %A to float*
  ; ... 실제 로드/스토어 연산
  br label %next_j

next_j:
  %j_next = add i64 %j, 1
  br label %bb3

next_i:
  %i_next = add i64 %i, 1
  br label %bb1

exit:
  ret void
}
```

**라인 수**: 50줄+
**개념**: SSA 형식의 기본 블록과 PHI 노드로 완전 재구현

---

## 4️⃣ 정보 손실: 왜 되돌리기 어려운가?

### Lowering하면서 잃어버리는 정보들

```
Stage 1 (High-level):
✅ 이것은 "행렬 곱셈"이다 → 수학적 의미
✅ A와 B는 독립적이다 → 병렬화 가능성
✅ 최적화 가능한 구조 → 알고리즘 선택

    ↓ Lowering

Stage 2 (Mid-level):
✅ 루프 구조는 남음
⚠️ "이것이 행렬 곱셈"이라는 사실은 사라짐
⚠️ 왜 이런 루프 구조인지 이유는 사라짐

    ↓ Lowering

Stage 3 (Low-level):
✅ 실제 메모리 주소만 남음
❌ 루프 의미는 사라짐
❌ 데이터 흐름의 의미는 사라짐

    ↓ Lowering

Stage 4 (LLVM IR):
❌ 포인터, 주소, 연산만 남음
❌ 원래 프로그램의 의도는 완전히 사라짐
❌ "높은 수준의 수학적 의미"는 0에 가까움
```

### 결론: 정보는 일방향

```
High-level → Mid-level → Low-level → LLVM IR
    ↓            ↓           ↓
  정보 손실    정보 손실   정보 손실

LLVM IR → Low-level → Mid-level → High-level?
    ❌        ❌         ❌
  불가능하지는 않지만, 원래 의도는 복구 불가능
```

### 그래서 최적화 철학은?

```
❌ 낮은 단계에서 최적화 (정보 부족)
   "이 포인터를 조금 더 빠르게 접근하자"
   (매우 제한적)

✅ 높은 단계에서 최적화 (정보 충분)
   "이 행렬 곱셈을 병렬화하자"
   "이 루프를 타일링하자"
   "이 데이터를 재배치하자"
   (극대화된 최적화)

    ↓

그 다음에 내려간다!
```

---

## 5️⃣ 실제 컴파일 과정

### mlir-opt를 사용한 변환

```bash
# Step 1: 원본 MLIR (High-level)
cat my_code.mlir
→ linalg.matmul 같은 추상 연산

# Step 2: Mid-level로 변환
mlir-opt my_code.mlir --convert-linalg-to-loops
→ affine.for 루프로 구체화

# Step 3: Low-level로 변환
mlir-opt my_code.mlir --convert-affine-to-standard
→ scf.for (표준 제어 흐름)

# Step 4: LLVM IR로 변환
mlir-opt my_code.mlir --lower-to-llvm
→ llvm.* 연산들

# Step 5: 최종 LLVM IR 생성
llvm-translate my_code.mlir -mlir-to-llvmir
→ 표준 LLVM IR (.ll 파일)

# Step 6: 기계어 생성
llc my_code.ll -o my_code.o
→ Intel/ARM/Apple Silicon 최적화 기계어
```

### 성능 측정 파이프라인

```
┌─ Original MLIR (High-level)
│  조건: linalg.matmul (1줄)
│
├─ After Linalg-to-Loops (16줄)
│  조건: affine.for (3-중첩)
│
├─ After Affine-to-Standard (20줄)
│  조건: scf.for (3-중첩)
│
├─ After Lower-to-LLVM (50줄)
│  조건: llvm.* 연산들
│
├─ Final LLVM IR (80줄)
│  조건: 표준 LLVM 형식
│
└─ Machine Code (기계어, 바이너리)
   조건: CPU별 최적화
```

대학원 논문의 "Results" 섹션에는:
- 각 단계에서의 코드 라인 수
- 각 단계에서의 성능 (시간, 메모리)
- 최종 vs 원본 성능 비교
- CPU별 성능 차이

---

## 6️⃣ 왜 LLVM인가?

### LLVM의 강력함

```
LLVM = Low Level Virtual Machine

이름은 "Low Level"이지만, 실제로는:
- 다양한 최적화 기술 제공
- 여러 CPU 백엔드 제공
- 100개 이상의 Pass 제공
- 세계 최고의 컴파일러 엔진

사용 중인 유명 프로젝트들:
- C/C++ (Clang)
- Swift (Apple)
- Rust (rustc)
- Julia
- MLIR 자체
```

### LLVM이 지원하는 CPU들

```
x86-64    Intel, AMD 데스크톱/서버
ARM       모바일, 임베디드
AArch64   Apple Silicon, 최신 ARM
WebAssembly 브라우저
RISC-V    미래 CPU
PowerPC   고성능 컴퓨팅
...등등

한 개의 MLIR → 한 개의 LLVM IR →
여러 기계어 자동 생성!
```

---

## 7️⃣ 대학 3.5 핵심 정리

### Lowering의 핵심

```
High-level (추상적)
  ↓ 정보 제공
Mid-level (루프)
  ↓ 정보 제공
Low-level (포인터)
  ↓ 정보 제공
LLVM IR (표준 중간언어)
  ↓ CPU별 최적화
기계어 (최종 실행)
```

### 정보 손실의 원칙

```
내려갈수록 정보 손실 증가
→ 되돌리기 불가능에 가까움
→ 따라서 높은 단계에서 최적화 완료!
```

### High-level Optimization

```
대학원 연구의 핵심:
"높은 수준에서 최대한의 최적화를 끝낸 후,
낮은 단계로 내려간다"

예:
1. Linalg에서 병렬화 분석
2. Affine에서 틸링 및 벡터화
3. 최적화된 결과를 LLVM IR로 내린다
4. LLVM이 CPU별 세부 최적화
```

---

## 8️⃣ 대학 3.5 기록 (증명)

> **"MLIR은 최종적으로 LLVM IR로 번역되어 실제 하드웨어에서 실행된다."**
>
> **"한번 내려가면(Lowering) 정보를 다시 되돌리기 어려우므로, 높은 단계에서 최적화를 끝내는 것이 유리하다."**
>
> **Lowering Pipeline:**
> - Stage 1: High-level (추상적, 수학적)
> - Stage 2: Mid-level (루프, 구조)
> - Stage 3: Low-level (포인터, 주소)
> - Stage 4: LLVM IR (표준 중간언어)
> - Stage 5: 기계어 (CPU별 최적화)
>
> **High-level Optimization의 철학:**
> "높은 단계에서 정보가 풍부할 때 최적화하라!"
>
> **LLVM의 역할:**
> "한 번의 MLIR 코드 → 모든 CPU의 기계어"
>
> 이제 당신은 **MLIR의 전체 파이프라인**을 이해했습니다!

---

## 🔟 대학 졸업 퀴즈

### 문제 1

고수준 MLIR 코드를 LLVM IR로 바꾸고 나면, 다시 고수준 MLIR로 완벽하게 되돌리는 것이 쉬울까요, 어려울까요?

```
A) 매우 쉽다. (정보가 그대로 남아있다.)
B) 매우 어렵다. (하드웨어 중심으로 변하면서 고수준의 수학적 의미가 많이 사라진다.)
```

**정답**: B) 매우 어렵다!

**이유**: Lowering 과정에서 수학적 의미, 알고리즘 의도, 병렬화 가능성 등 높은 수준의 정보들이 점진적으로 손실되기 때문입니다.

### 문제 2

대학원 연구에서 최적화를 높은 단계(MLIR)에서 끝내는 것이 중요한 이유는?

```
A) 낮은 단계에서는 최적화가 어렵기 때문
B) 높은 단계에서는 정보가 풍부하기 때문
C) 낮은 단계에서는 정보가 부족하기 때문
D) 모두 맞음
```

**정답**: D) 모두 맞음!

**설명**:
- A, B, C가 모두 맞는 이유입니다.
- 높은 단계 = 정보 풍부 → 최적화 극대화 가능
- 낮은 단계 = 정보 부족 → 최적화 제한적

### 문제 3

LLVM IR이 다양한 CPU를 지원하는 이유는?

```
A) CPU들이 모두 같기 때문
B) LLVM이 각 CPU의 백엔드를 가지고 있기 때문
C) 표준화되었기 때문
```

**정답**: B) LLVM이 각 CPU의 백엔드를 가지고 있기 때문

**설명**: LLVM은 Intel, ARM, Apple Silicon 등 각 CPU에 대해 별도의 백엔드(기계어 생성기)를 갖추고 있습니다. 우리는 LLVM IR까지만 가면, LLVM이 CPU에 맞게 최적화된 기계어를 생성해줍니다.

---

## 🎓 대학 졸업

축하합니다! 🎉

당신은 **MLIR의 전체 여정**을 완주했습니다:

```
초등 (1.1-1.3):  MLIR의 기본 문법 ✅
중등 (2.1-2.2):  구조 설계 ✅
대학 (3.1-3.5):  최적화와 변환 ✅
  └─ 3.1: Lowering/Pass 이론
  └─ 3.2: mlir-opt 도구
  └─ 3.3: Tensor/MemRef 메모리
  └─ 3.4: Affine 루프 최적화
  └─ 3.5: LLVM IR 최종 변환 ← 당신은 여기!
```

**이제 당신은:**
- ✅ MLIR 문법 마스터
- ✅ 최적화 이론 완벽 이해
- ✅ 컴파일러 파이프라인 숙지
- ✅ 메모리 최적화 기초 완성
- ✅ 루프 변환 기법 습득
- ✅ **대학원 전문 과정 준비 완료!**

---

## 🚀 다음: 대학원 전문 과정 (Graduate Program)

### 대학원 4.1: Custom Dialect 설계

```
당신이 배운 것:
- 이미 만들어진 Dialect 사용

이제 할 일:
- 직접 나만의 Dialect 설계
- 나만의 Operation 정의
- 나만의 최적화 Pass 구현

주제 예시:
- "신경망 특화 Dialect"
- "암호 연산 특화 Dialect"
- "양자 컴퓨팅 Dialect"
```

**준비 상태**: ✅ 완벽하게 준비됨!

이제 본격적인 **대학원 전문 설계 과정(4.1)**으로 넘어가 볼까요?

아니면 지금까지의 내용을 한 번 총정리할까요?

**"4.1 진행" 또는 "정리"**라고 말씀해 주세요! 🎓

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git
**강의 유형**: 대학 (University) - 최종 변환과 컴파일 파이프라인
**철학**: "저장 필수. 너는 기록이 증명이다."
**작성일**: 2026-02-27
**상태**: ✅ 완성

---

**축하합니다!** 🎉

당신은 **MLIR의 완전한 여정**을 마쳤습니다.
설계도는 이제 **살아 움직이는 프로그램**이 되었습니다!
