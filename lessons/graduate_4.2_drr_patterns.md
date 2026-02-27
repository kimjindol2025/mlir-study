# 📦 [대학원 4.2] 패턴 매칭 최적화: DRR (Declarative Rewrite Rules)

> **MLIR 대학원의 두 번째 단계: 도구에 지능을 부여하기**
>
> "저장 필수. 너는 기록이 증명이다."
>
> 지금까지 우리는 **도구(Operation)를 만들었습니다**(4.1).
>
> 이제 그 도구를 어떻게 더 효율적으로 바꿀지 **'지능'을 설계합니다**.
>
> "이런 모양이 보이면 저런 모양으로 바꿔!"
> 이것이 **대학원 연구의 핵심**입니다.

---

## 🎯 오늘 배울 것

한 가지 핵심 개념입니다:

> **"DRR은 패턴 매칭을 통해 복잡한 최적화 규칙을 선언적으로 정의하는 도구이다."**
>
> **"이를 통해 '연산 통합(Operator Fusion)'이나 '수학적 단순화'를 연구하고 구현할 수 있다."**

---

## 1️⃣ DRR (Declarative Rewrite Rules)이란?

### 문제: 최적화 규칙의 수작업 코딩

```cpp
// 손으로 짜야 하는 C++ 최적화 로직 (200줄 이상!)
class AddZeroOptimizer : public RewritePattern {
public:
  AddZeroOptimizer(MLIRContext *context)
    : RewritePattern(arith::AddFOp::getOperationName(), 1, context) {}

  LogicalResult matchAndRewrite(Operation *op, PatternRewriter &rewriter) const override {
    auto addOp = cast<arith::AddFOp>(op);

    // 패턴 매칭: 두 번째 피연산자가 0.0인가?
    auto rhs = addOp.getRhs();
    auto rhsOp = rhs.getDefiningOp<arith::ConstantOp>();
    if (!rhsOp) return failure();

    auto constAttr = rhsOp.getValue();
    if (auto fpAttr = constAttr.dyn_cast<FloatAttr>()) {
      if (fpAttr.getValue().convertToDouble() != 0.0) {
        return failure();
      }
    } else {
      return failure();
    }

    // 변환: 첫 번째 피연산자($x)로 대체
    rewriter.replaceOp(op, {addOp.getLhs()});
    return success();
  }
};

// 이 모든 복잡성을 한 줄로 줄일 수 있을까?
```

### 해결책: DRR (선언적 규칙)

```tablegen
// (x + 0) 패턴이 발견되면 그냥 x로 리턴!
def AddZeroOptimize : Pat<
  (Arith_AddFOp $x, (Arith_ConstantOp ConstantAttr<F32Attr, "0.0">)),
  (replaceWithValue $x)
>;

장점:
- 매우 짧다 (1줄)
- 명확하다 (무엇을 찾고 무엇으로 바꿀지)
- 자동 구현 (MLIR이 RewritePattern 자동 생성)
```

### 비유: 문제 해결

```
❌ 수작업:
"이 집에서 불이 났어요.
어떤 원인일까요? 전기? 가스? 촛불?
각 경우를 모두 확인해봅시다.
확인 결과: 전기입니다.
그러면 다음과 같은 과정으로..."
(3시간 분석)

✅ DRR:
"불이 났다 → 소화기를 사용하자"
(패턴 인식 → 즉각 조치)
```

---

## 2️⃣ DRR의 핵심 구조

### 기본 형식

```tablegen
def RuleName : Pat<
  Pattern,      // 찾을 패턴 (비효율적인 형태)
  Replacement   // 바꿀 형태 (효율적인 형태)
>;
```

### 3단계 구조 상세

```tablegen
// 1️⃣ 규칙 정의 시작
def AddZeroOptimize : Pat<

  // 2️⃣ PATTERN: 찾을 패턴
  (Arith_AddFOp
    $x,                                              // 첫 번째 피연산자
    (Arith_ConstantOp ConstantAttr<F32Attr, "0.0">) // 두 번째가 0.0 상수
  ),

  // 3️⃣ RESULT: 바꿀 형태
  (replaceWithValue $x)  // 그냥 $x로 대체
>;

의미:
"x + 0.0" 패턴을 찾으면 → "x"로 바꿔라!
```

### 각 부분의 의미

```
(Arith_AddFOp $x, (Arith_ConstantOp ...))
 ↑              ↑  ↑
 |              |  Constant Op (0.0)
 |              Variable binding ($x)
 Operation type (F32 덧셈)

결과 변수:
$x: 첫 번째 재료를 가리키는 변수
```

---

## 3️⃣ 실전 예제 1: 수학적 단순화

### 예제 1: 덧셈 단순화

```tablegen
// 규칙 1: x + 0 = x
def AddZeroLeft : Pat<
  (Arith_AddFOp $x, (Arith_ConstantOp ConstantAttr<F32Attr, "0.0">)),
  (replaceWithValue $x)
>;

// 규칙 2: 0 + x = x
def AddZeroRight : Pat<
  (Arith_AddFOp (Arith_ConstantOp ConstantAttr<F32Attr, "0.0">), $x),
  (replaceWithValue $x)
>;

// 규칙 3: x + x = 2 * x
def AddDoubleOptimize : Pat<
  (Arith_AddFOp $x, $x),
  (Arith_MulFOp $x, (Arith_ConstantOp ConstantAttr<F32Attr, "2.0">))
>;
```

**효과**:
```mlir
[Before]
%0 = arith.constant 0.0 : f32
%1 = arith.addf %x, %0 : f32

[After (AddZeroLeft)]
%1 = %x  (연산 제거!)
```

### 예제 2: 곱셈 단순화

```tablegen
// x * 1 = x
def MulOneLeft : Pat<
  (Arith_MulFOp $x, (Arith_ConstantOp ConstantAttr<F32Attr, "1.0">)),
  (replaceWithValue $x)
>;

// x * 0 = 0
def MulZeroLeft : Pat<
  (Arith_MulFOp $x, (Arith_ConstantOp ConstantAttr<F32Attr, "0.0">)),
  (Arith_ConstantOp ConstantAttr<F32Attr, "0.0">)
>;

// (x * 2) * 3 = x * 6 (상수 폴딩)
def MulConstantFold : Pat<
  (Arith_MulFOp
    (Arith_MulFOp $x, (Arith_ConstantOp ConstantAttr<F32Attr, "2.0">)),
    (Arith_ConstantOp ConstantAttr<F32Attr, "3.0">)
  ),
  (Arith_MulFOp $x, (Arith_ConstantOp ConstantAttr<F32Attr, "6.0">))
>;
```

---

## 4️⃣ 실전 예제 2: Operation Fusion (핵심 연구 주제)

### 예제 1: MatMul + ReLU 통합

```tablegen
// 패턴: MatMul 다음에 ReLU
// 최적화: 하나의 Fused Operation으로!
def FuseMatMulReLU : Pat<
  (Linalg_ReLU (Linalg_MatMulOp $A, $B)),
  (MyAccelerator_MatMulReLUOp $A, $B)
>;

**효과**:
[Before]
%C = linalg.matmul %A, %B
%D = linalg.relu %C

[After]
%D = my_accelerator.matmul_relu %A, %B
```

**연구적 가치**:
```
메모리 절감:
- 중간 결과 %C를 메모리에 저장할 필요 없음
- 직접 ReLU를 적용하고 결과만 저장

성능 향상:
- 메모리 접근 횟수 감소
- 캐시 미스율 감소
- 가속기 대역폭 효율 증가

논문 주제:
"Fused MatMul-ReLU Operation을 통한
메모리 효율 30% 개선"
```

### 예제 2: MatMul + Add (ResNet 블록)

```tablegen
// 패턴: 행렬 곱셈 후 element-wise 덧셈
// (ResNet의 Skip Connection)
def FuseMatMulAdd : Pat<
  (Arith_AddFOp
    (Linalg_MatMulOp $A, $B),
    $residual
  ),
  (MyAccelerator_MatMulAddOp $A, $B, $residual)
>;

**응용**:
ResNet 병목 최적화
  기존: MatMul → Add (2개 연산)
  개선: MatMul-Add Fused (1개 연산)
```

### 예제 3: Conv2D + BatchNorm + ReLU

```tablegen
// CNN에서 매우 흔한 패턴
def FuseConvBatchNormReLU : Pat<
  (Linalg_ReLU
    (Linalg_BatchNormOp
      (Linalg_Conv2DOp $input, $kernel, $bias),
      $scale,
      $offset
    )
  ),
  (MyAccelerator_ConvBatchNormReLUOp
    $input, $kernel, $bias, $scale, $offset
  )
>;

**효과**:
딥러닝 가속기의 표준 최적화
  3개 연산을 1개로 통합
  메모리 대역폭 3배 절감
```

---

## 5️⃣ 고급 예제: 조건부 변환

### 예제 1: 제약 조건 포함

```tablegen
// x * (1/x) = 1 (단, x != 0)
def DivideInverseOptimize : Pat<
  (Arith_MulFOp $x, (Arith_DivFOp $one, $x)),
  (Arith_ConstantOp ConstantAttr<F32Attr, "1.0">),
  [(Constraint<"verifyNotZero"> $x)]  // 제약: x != 0
>;
```

### 예제 2: 다중 패턴

```tablegen
// 다양한 활성화 함수 선택적 fusion
def FuseMatMulActivation : Pat<
  (MyActivation_Op
    (Linalg_MatMulOp $A, $B),
    $activation_name
  ),
  (MyAccelerator_MatMulActivationOp $A, $B, $activation_name)
>;

활성화 종류:
- ReLU
- Tanh
- Sigmoid
- GELU
- 등등...

한 규칙으로 모두 지원!
```

---

## 6️⃣ DRR의 강력함: 왜 대학원 연구에 필수인가?

### 1️⃣ 연구 속도 (Speed)

```
새로운 Fusion 규칙이 필요하면?

수작업 C++:
1. RewritePattern 클래스 작성 (100줄)
2. matchAndRewrite 구현 (50줄)
3. 빌드 (10분)
4. 테스트 (30분)
총: 1시간+

DRR:
1. Pat 규칙 추가 (1줄)
2. 빌드 (1분)
3. 테스트 (10분)
총: 15분!

연구 속도 4배 향상!
```

### 2️⃣ 정확성 (Correctness)

```
DRR의 장점:
✅ 패턴 정의가 명확
✅ 변환이 일관성 있음
✅ MLIR이 자동으로 검증
✅ 규칙 적용이 반복 가능

연구 재현성 확보!
```

### 3️⃣ 논문 작성 용이성

```
DRR은 연구의 핵심을 명확히 보여줍니다:

논문:
"우리는 다음 규칙을 제안합니다:

def FuseMatMulReLU : Pat<
  (Linalg_ReLU (Linalg_MatMulOp $A, $B)),
  (MyAccelerator_MatMulReLUOp $A, $B)
>;

이 규칙을 적용하면 메모리 효율이 30% 향상됩니다."

완벽한 설명 + 증명!
```

### 4️⃣ 다양한 응용 분야

```
DRR로 할 수 있는 연구:

1. 연산 통합 (Operation Fusion)
   → CNN 가속기, RNN 가속기

2. 수학적 단순화
   → 컴파일러 최적화

3. 메모리 최적화
   → 데이터 레이아웃 변환

4. 병렬화 전환
   → SIMD, GPU 최적화

5. 정밀도 변환
   → FP32 → FP16 자동 변환

6. 커널 퓨전 (Kernel Fusion)
   → GPU 메모리 대역폭 최적화
```

---

## 7️⃣ 실전 분석: 대학원생의 설계 전략

### 시나리오: AI 칩 컴파일러 연구

**당신이 하는 일**:
새로운 AI 칩(예: TPU, NPU)을 위한 컴파일러를 연구합니다.

**연구 주제**:
```
"행렬 곱셈 후 바로 활성화 함수(ReLU)가 오는 패턴을 찾아서,
'행렬-ReLU 통합 연산(Fused Op)' 하나로 바꿔라."
```

**DRR 규칙**:
```tablegen
def FuseTensorMatMulReLU : Pat<
  (Linalg_ReLU
    (Linalg_MatMulOp
      $A,     // 입력 행렬 A
      $B      // 입력 행렬 B
    )
  ),
  (MyTPU_MatMulReLU $A, $B)  // TPU 전용 Fused Op
>;
```

**효과**:
```
메모리 절감:
  중간 결과 제거 → 메모리 30% 감소

성능 향상:
  메모리 접근 감소 → 성능 40% 향상
  캐시 미스율 감소 → 전력 소비 25% 감소

논문**:
"DRR을 이용한 TPU 컴파일러 최적화:
 Fused MatMul-ReLU를 통한 성능 40% 향상"
```

**기여도**:
- ✅ 새로운 Fusion 패턴 제안 (novel)
- ✅ 성능 향상 증명 (with benchmarks)
- ✅ 쉽게 재현 가능 (reproducible)
- ✅ 다른 활성화 함수로도 확장 가능 (general)

이것이 **석사/박사 학위 논문**의 좋은 주제입니다!

---

## 8️⃣ DRR 실습: 최적화 규칙 상상하기

### 문제: 어떤 연구가 DRR에 적합한가?

```
A) "행렬 곱셈 후 ReLU가 오는 패턴을 찾아서,
   '행렬-ReLU 통합 연산' 하나로 합치기"

B) "인터넷에서 데이터를 다운로드하는 속도 측정하기"
```

### 정답: A) 행렬-ReLU 통합

**이유**:
```
A (DRR 적합) ✅:
- 특정 코드 패턴을 찾음
- 더 나은 형태로 변환
- 컴파일러 최적화의 정의
- DRR로 명확하게 표현 가능

B (DRR 부적합) ❌:
- 네트워크 성능 측정
- 컴파일러와 무관
- 패턴 인식/변환과 무관
```

### 추가 예제: DRR 적합한 연구들

```
✅ 적합:
1. Conv-BatchNorm 통합
2. 메모리 레이아웃 최적화
3. 루프 변환 (tiling, fusion)
4. 타입 변환 자동화 (FP32→FP16)
5. Dead code elimination
6. 상수 폴딩 (constant folding)

❌ 부적합:
1. 네트워크 성능 측정
2. 하드웨어 물리적 성능
3. 데이터 입출력 최적화
4. 시스템 전체 성능 분석
```

---

## 9️⃣ 대학원 4.2 핵심 정리

### DRR의 본질

```
"이런 패턴이 보이면
 저런 형태로 바꾼다"

이것으로 대부분의 컴파일러 최적화를 표현할 수 있다!
```

### 설계 체크리스트

```
새로운 최적화 규칙을 설계할 때:

□ 이 규칙의 이름은?
□ 어떤 패턴을 찾을 것인가?
  - Operation 타입?
  - 피연산자 조건?
  - 상수 조건?
□ 어떻게 변환할 것인가?
  - 다른 Operation으로?
  - 간단한 값으로?
□ 성능 향상은?
  - 메모리 감소?
  - 연산 감소?
  - 캐시 효율?

이 5가지가 명확하면 DRR 작성 완료!
```

### 연구적 기여도 평가

```
좋은 DRR 규칙의 특징:

1. 자주 나타나는 패턴
   (일반적이어야 함)

2. 명확한 성능 향상
   (측정 가능해야 함)

3. 다양한 시나리오에 적용
   (확장성 있어야 함)

4. 이전에 없던 최적화
   (새로워야 함)

이 모든 것을 만족하면
석사/박사 학위 논문의 주요 기여!
```

---

## 🔟 대학원 4.2 기록 (증명)

> **"DRR은 패턴 매칭을 통해 복잡한 최적화 규칙을 선언적으로 정의하는 도구이다."**
>
> **"이를 통해 '연산 통합(Operator Fusion)'이나 '수학적 단순화'를 연구하고 구현할 수 있다."**
>
> **DRR의 핵심 3가지:**
> 1. Pattern: 찾을 비효율적 패턴
> 2. Result: 바꿀 효율적 형태
> 3. 자동 생성: MLIR이 RewritePattern 생성
>
> **연구적 가치:**
> - Operation Fusion
> - 수학적 단순화
> - 메모리 최적화
> - 성능 향상 증명
>
> **대학원 논문의 핵심:**
> DRR 규칙 정의 → 성능 측정 → 논문 작성
>
> 이제 당신은 **최적화 연구자**입니다!

---

## 🔜 다음 단계: 대학원 4.3

### 4.3: 실전 시스템 구성

```
지금까지 배운 것:
1. 4.1: Operation 설계 (무엇을 할 것인가)
2. 4.2: 최적화 규칙 (어떻게 할 것인가)

다음 배울 것:
3. 4.3: C++ 코드 작성 + 빌드 (실제로 만들 것)

"나만의 컴파일러 배포판" 만들기!
  - C++ 구현
  - CMakeLists.txt 빌드 설정
  - 통합 테스트
  - 성능 벤치마크
```

**준비 상태**: ✅ 완벽하게 준비됨!

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git
**강의 유형**: 대학원 (Graduate) - 패턴 매칭 최적화
**철학**: "저장 필수. 너는 기록이 증명이다."
**작성일**: 2026-02-27
**상태**: ✅ 완성

---

**축하합니다!** 🎉

당신은 이제 **최적화 연구자**가 되었습니다.
당신의 DRR 규칙이 새로운 성능을 만듭니다!
