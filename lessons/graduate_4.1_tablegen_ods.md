# 📦 [대학원 4.1] 나만의 언어 설계: TableGen과 ODS

> **MLIR 대학원의 첫 번째 단계: 창조자의 영역**
>
> "저장 필수. 너는 기록이 증명이다."
>
> 지금까지 우리는 **남이 만든 도구(arith, linalg, affine)를 사용**했습니다.
>
> 이제부터는 **세상에 없던 새로운 규칙을 설계하는 '창조자'**의 영역입니다.
>
> 당신의 독창적인 연구 기록이 곧 학위의 증명이 될 것입니다.

---

## 🎯 오늘 배울 것

한 가지 핵심 개념입니다:

> **"대학원 수준의 설계는 TableGen(.td)을 이용해 선언적으로 Dialect를 정의하는 것부터 시작한다."**
>
> **"ODS를 통해 재료(arguments)와 결과(results)를 정의하면 MLIR이 C++ 인프라를 자동으로 구축해 준다."**

---

## 1️⃣ ODS (Operation Definition Specification)란?

### 문제: 수동 C++ 코딩의 고통

```cpp
// 손으로 써야 하는 C++ 코드 (100줄 이상!)
class MyCustomAddOp : public Operation {
public:
  static StringRef getOpName() { return "my.add"; }

  MLIRContext *context = nullptr;
  SmallVector<Value, 2> operands;
  SmallVector<Type, 1> results;

  // SSA 규칙 확인
  bool verify() {
    if (operands.size() != 2) return false;
    if (operands[0].getType() != operands[1].getType()) return false;
    return true;
  }

  // Printer 구현
  void print(OpAsmPrinter &p) {
    p << "my.add " << operands[0] << ", " << operands[1];
  }

  // Parser 구현
  ParseResult parse(OpAsmParser &parser, OperationState &state) {
    // ... 복잡한 파싱 로직
  }

  // ... 50줄 더
};

문제:
- 매우 길다 (100줄 이상)
- 실수하기 쉽다 (SSA 규칙, 타입 체크)
- 수정하기 어렵다 (여러 곳을 고쳐야 함)
```

### 해결책: ODS (선언적 정의)

```tablegen
def MyCustomAddOp : MyDialect_Op<"my_add"> {
  let summary = "나만의 특별한 더하기 연산";

  // 재료(Input) 정의
  let arguments = (ins F32:$lhs, F32:$rhs);

  // 결과(Output) 정의
  let results = (outs F32:$result);
}

장점:
- 매우 짧다 (5줄)
- 명확하다 (무엇을 받고 무엇을 내보낼지 한눈에)
- 자동 생성 (MLIR이 C++ 코드 생성)
```

### 비유: 요리 레시피

```
❌ 수동 C++ 코딩:
"달걀을 냄비에 넣고 불을 켠다.
열이 달걀을 어느 정도 익히는지 지켜본다.
온도를 조절하면서 산소가...
(과학 논문 수준의 설명)"

✅ ODS:
"달걀 계란 2개 + 우유 100ml → 계란말이"

MLIR: "알겠습니다! 자동으로 요리해드리겠습니다!"
```

---

## 2️⃣ TableGen의 핵심 구조 (.td 파일)

### 기본 구조

```tablegen
// 1. Dialect 정의
def MyDialect : Dialect {
  let name = "my";
  let description = "나만의 커스텀 Dialect";
}

// 2. Operation 정의
def MyCustomAddOp : MyDialect_Op<"my_add"> {
  // 메타데이터
  let summary = "나만의 특별한 더하기 연산";
  let description = [{
    두 개의 F32 값을 받아서 더하는 연산입니다.
    일반 덧셈과 다르게 우리 가속기에 최적화되어 있습니다.
  }];

  // 재료(Input)
  let arguments = (ins
    F32:$lhs,           // 왼쪽 재료
    F32:$rhs            // 오른쪽 재료
  );

  // 결과(Output)
  let results = (outs
    F32:$result         // 결과값
  );

  // 추가 옵션
  let hasFolder = 1;    // 상수 폴딩 지원
  let hasVerifier = 1;  // 검증 함수 포함
}
```

### 각 부분의 의미

```
def MyCustomAddOp : MyDialect_Op<"my_add">
  ↑   ↑                 ↑                ↑
  |   나만의 Operation  |                아래에서 보일 Operation 이름
  TableGen에서의 정의명 (내부용)


let arguments = (ins F32:$lhs, F32:$rhs)
             ↑    ↑              ↑
         정의 시작  재료 타입       변수명 (MLIR에서 접근 가능)


let results = (outs F32:$result)
           ↑    ↑              ↑
       정의 시작  결과 타입     변수명
```

### 타입 지정 방법

```tablegen
// 기본 숫자 타입
I32:$operand              // 32비트 정수
F32:$operand              // 32비트 실수
F64:$operand              // 64비트 실수

// 컨테이너 타입
Tensor<"F32">:$matrix     // 임의 크기 F32 텐서
MemRef<"F32">:$buffer     // F32 MemRef

// 속성 (Operation의 고정 값)
Attr<"IntegerAttr">:$count     // 정수 속성
Attr<"StringAttr">:$name       // 문자열 속성

// 다중 피연산자
Variadic<F32>:$values    // 여러 개의 F32 (가변 길이)

// 선택적 피연산자
Optional<F32>:$bias      // 있을 수도, 없을 수도 있음
```

---

## 3️⃣ 실전 예제: 가속기 행렬 곱셈

### 예제 1: 단순 행렬 곱셈

```tablegen
def AcceleratorMatMulOp : MyAccelerator_Op<"matmul"> {
  let summary = "가속기 전용 행렬 곱셈";
  let description = [{
    A × B = C 행렬 곱셈을 가속기에서 수행합니다.

    Example:
    ```mlir
    %C = my.matmul %A, %B : (tensor<4x4xf32>, tensor<4x4xf32>) -> tensor<4x4xf32>
    ```
  }];

  // 재료: 두 개의 행렬
  let arguments = (ins
    Tensor<"F32">:$A,      // 왼쪽 행렬
    Tensor<"F32">:$B       // 오른쪽 행렬
  );

  // 결과: 결과 행렬
  let results = (outs
    Tensor<"F32">:$C       // 결과 행렬
  );

  let hasFolder = 1;
  let hasVerifier = 1;
}
```

**MLIR 코드에서의 사용**:
```mlir
%C = my.matmul %A, %B : (tensor<4x4xf32>, tensor<4x4xf32>) -> tensor<4x4xf32>
```

### 예제 2: 곱셈 + 활성화 함수 (Fused Operation)

```tablegen
def FusedMatMulActivationOp : MyAccelerator_Op<"matmul_relu"> {
  let summary = "행렬 곱셈 + ReLU 활성화 (Fused)";
  let description = [{
    행렬 곱셈과 ReLU를 한 번에 처리합니다.
    일반적으로: C = matmul(A, B); C = relu(C)
    우리는 한 번에: C = matmul_relu(A, B)

    가속기 수준에서 최적화됩니다!
  }];

  let arguments = (ins
    Tensor<"F32">:$A,           // 입력 행렬 1
    Tensor<"F32">:$B,           // 입력 행렬 2
    Attr<"F32Attr">:$alpha      // ReLU의 기울기 (선택적)
  );

  let results = (outs
    Tensor<"F32">:$C            // 결과 행렬
  );

  let hasFolder = 1;
  let hasVerifier = 1;
}
```

**MLIR 코드에서의 사용**:
```mlir
%C = my.matmul_relu %A, %B { alpha = 0.1 : f32 } : (tensor<4x4xf32>, tensor<4x4xf32>) -> tensor<4x4xf32>
```

### 예제 3: 가변 길이 덧셈 (여러 행렬)

```tablegen
def MultiInputAddOp : MyAccelerator_Op<"multi_add"> {
  let summary = "여러 행렬의 합";
  let description = [{
    여러 개의 행렬을 모두 더합니다.

    Example:
    ```mlir
    %result = my.multi_add %A, %B, %C : tensor<4x4xf32>
    ```
  }];

  // 가변 길이 입력
  let arguments = (ins
    Variadic<Tensor<"F32">>:$inputs   // 몇 개든 가능
  );

  let results = (outs
    Tensor<"F32">:$result
  );

  let hasFolder = 1;
  let hasVerifier = 1;
}
```

**MLIR 코드에서의 사용**:
```mlir
%result = my.multi_add %A, %B, %C, %D : tensor<4x4xf32>
```

### 예제 4: 선택적 편향 (Optional Input)

```tablegen
def MatMulWithBiasOp : MyAccelerator_Op<"matmul_bias"> {
  let summary = "행렬 곱셈 + 선택적 편향";

  let arguments = (ins
    Tensor<"F32">:$A,              // 입력 행렬 A
    Tensor<"F32">:$B,              // 입력 행렬 B
    Optional<Tensor<"F32">>:$bias  // 편향 (있을 수도, 없을 수도)
  );

  let results = (outs
    Tensor<"F32">:$C               // 결과
  );

  let hasVerifier = 1;
}
```

**MLIR 코드에서의 사용**:
```mlir
// 편향 있음
%C = my.matmul_bias %A, %B, %bias : tensor<4x4xf32>

// 편향 없음
%C = my.matmul_bias %A, %B : tensor<4x4xf32>
```

---

## 4️⃣ TableGen이 생성하는 C++ 코드

### 당신이 작성하는 코드 (.td)

```tablegen
def MyAddOp : MyDialect_Op<"my_add"> {
  let summary = "나만의 덧셈";
  let arguments = (ins F32:$lhs, F32:$rhs);
  let results = (outs F32:$result);
}
```

### MLIR이 자동으로 생성하는 코드 (C++)

```cpp
// 자동 생성 (100줄+)
class MyAddOp : public Operation {
public:
  static StringRef getOpName() {
    return "my.add";
  }

  static void build(Builder &builder, OperationState &state,
                    Value lhs, Value rhs) {
    state.addOperands({lhs, rhs});
    state.types.push_back(builder.getF32Type());
  }

  Value getLhs() {
    return getOperand(0);
  }

  Value getRhs() {
    return getOperand(1);
  }

  Value getResult() {
    return getResult(0);
  }

  bool verify() {
    if (getNumOperands() != 2) return false;
    auto lhsType = getLhs().getType();
    auto rhsType = getRhs().getType();
    if (lhsType != rhsType) return false;
    return true;
  }

  void print(OpAsmPrinter &p) {
    p << "my.add " << getLhs() << ", " << getRhs();
  }

  static ParseResult parse(OpAsmParser &parser, OperationState &state) {
    Value lhs, rhs;
    Type type;
    if (parser.parseOperand(lhs) ||
        parser.parseComma() ||
        parser.parseOperand(rhs) ||
        parser.parseColonType(type)) {
      return failure();
    }
    state.addOperands({lhs, rhs});
    state.types.push_back(type);
    return success();
  }

  // ... 30줄 더
};

// 100줄의 코드를 단 5줄의 TableGen으로!
```

---

## 5️⃣ ODS의 강력함: 왜 대학원에서 필수인가?

### 1️⃣ 정확성 (Correctness)

```
수동 C++ 코딩:
❌ SSA 규칙 위반 가능
❌ 타입 체크 실수
❌ Printer/Parser 불일치

ODS:
✅ MLIR이 규칙 자동 적용
✅ 타입 체크 자동 생성
✅ 일관성 보장
```

### 2️⃣ 속도 (Speed)

```
새로운 Operation이 필요하면?

수동 C++:
1. .cpp 파일 생성 (30분)
2. 코드 작성 (2시간)
3. 컴파일 (10분)
4. 테스트 (30분)
총: 3시간+

ODS:
1. .td 파일에 정의 추가 (5분)
2. 자동 생성 (1분)
3. 테스트 (10분)
총: 15분!

연구 속도 12배 빨라짐!
```

### 3️⃣ 문서화 (Documentation)

```
ODS 파일 자체가:
✅ Operation의 명확한 정의
✅ 설계 의도 (summary, description)
✅ 입출력 스키마
✅ 논문의 기초 자료

대학원 논문 쓸 때:
"우리의 MyAddOp은 다음과 같이 정의됩니다:"
[ODS 코드 붙임]

완벽한 설명!
```

---

## 6️⃣ 실전 분석: 설계자의 시각

### 문제: 가속기 행렬 곱셈 설계

**당신이 해야 할 일**: 가속기 전용 행렬 곱셈 연산을 설계합니다.

**ODS의 arguments에 무엇을 넣어야 할까요?**

```
A) 단순한 숫자 두 개 (F32, F32)
B) 두 개의 행렬 데이터 (Tensor 또는 MemRef)
```

### 정답: B) 두 개의 행렬 데이터

**이유**:
```
가속기의 목적:
- 대량의 데이터를 빠르게 처리

따라서:
✅ Tensor<"F32">:$A    (대량 데이터)
✅ Tensor<"F32">:$B    (대량 데이터)

아니면:
❌ F32:$a              (단일 스칼라)
❌ F32:$b              (단일 스칼라)

왜냐하면:
- 가속기는 병렬 처리 능력이 특징
- 행렬 전체를 한 번에 처리할 수 있도록 설계해야 함
- 스칼라는 가속기의 능력을 낭비
```

### 확장된 설계 사고

```
가속기 설계자의 생각:

1단계 (기초):
"행렬 곱셈을 하자"
→ Tensor<"F32">:$A, Tensor<"F32">:$B

2단계 (최적화):
"배치 처리도 하자"
→ Variadic<Tensor<"F32">>:$matrices

3단계 (활성화):
"그냥 곱셈만? 실용성을 위해 ReLU도 넣자"
→ + Optional<Attr<"StringAttr">>:$activation

4단계 (성능):
"정밀도 옵션을 줄까?"
→ + Attr<"StringAttr">:$precision  // "FP32", "TF32", "FP16"

최종:
def AcceleratorMatMulOp : Accelerator_Op<"matmul"> {
  let arguments = (ins
    Variadic<Tensor>:$matrices,
    Optional<Attr<"StringAttr">>:$activation,
    Attr<"StringAttr">:$precision
  );
  let results = (outs Tensor:$result);
}
```

---

## 7️⃣ 대학원 4.1 핵심 정리

### ODS의 본질

```
"무엇을 받아서(arguments)
 무엇을 내보낼(results)
 것인가?"

이것만 명확하면
MLIR이 나머지는 다 해준다!
```

### 설계 체크리스트

```
새로운 Operation을 설계할 때:

□ 이 Operation의 이름은?
□ 이것이 하는 일은?
□ 입력으로 뭘 받나? (arguments)
□ 출력으로 뭘 내보나? (results)
□ 타입 검증이 필요한가?
□ 상수 폴딩이 가능한가?

이 5가지만 명확하면 ODS 작성 완료!
```

### TableGen 파일의 위치

```
my_dialect/
├── CMakeLists.txt
├── ops.h              (생성된 C++ 헤더)
├── ops.cpp            (구현)
└── MyDialect.td       ← 여기서 모든 것이 시작!
    ├── MyDialectOps.td (Operation 정의)
    ├── MyDialectTypes.td (타입 정의)
    └── MyDialectAttributes.td (속성 정의)
```

---

## 8️⃣ 대학원 4.1 기록 (증명)

> **"대학원 수준의 설계는 TableGen(.td)을 이용해 선언적으로 Dialect를 정의하는 것부터 시작한다."**
>
> **"ODS를 통해 재료(arguments)와 결과(results)를 정의하면 MLIR이 C++ 인프라를 자동으로 구축해 준다."**
>
> **ODS의 핵심 5가지:**
> 1. `def MyOp : Dialect_Op<"op_name">` - Operation 정의
> 2. `let summary = "..."` - 설명
> 3. `let arguments = (ins ...)` - 입력
> 4. `let results = (outs ...)` - 출력
> 5. `let hasVerifier = 1` - 검증
>
> **장점:**
> - 정확성: MLIR이 SSA 규칙 자동 적용
> - 속도: 12배 빠른 개발
> - 문서화: 설계 명세서가 곧 논문 자료
>
> 이제 당신은 **창조자의 영역**에 발을 디뎠습니다!

---

## 🔟 다음 단계: 대학원 4.2

### 4.2: DRR (Declarative Rewrite Rules)

```
지금 배운 것:
"내 도구의 형태(Operation)를 만든다"

다음 배울 것:
"내 도구를 똑똑하게 만든다"

예:
패턴 인식: "A = matmul(X, X)를 본다면?"
지능형 변환: "A를 matmul_square(X)로 바꾼다"
최적화: "더 빠른 연산으로 치환!"

```

**준비 상태**: ✅ 완벽하게 준비됨!

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git
**강의 유형**: 대학원 (Graduate) - Custom Dialect 설계
**철학**: "저장 필수. 너는 기록이 증명이다."
**작성일**: 2026-02-27
**상태**: ✅ 완성

---

**축하합니다!** 🎉

당신은 이제 **MLIR 창조자**의 영역에 진입했습니다.
당신만의 언어를 설계할 수 있습니다!
