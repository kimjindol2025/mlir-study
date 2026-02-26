# ✅ 초등 1.1 테스트 검증 보고서

**작성자**: 학생 (대학원 진학 목표)
**날짜**: 2026-02-27
**검증 대상**: elementary_1.1_code_examples.mlir
**목표**: SSA 규칙이 올바르게 적용되었는지 검증

---

## 🧪 테스트 항목별 검증

### 테스트 1: 예제 1 - 기본 더하기

**코드**:
```mlir
module {
  func.func @example_add(%a: i32, %b: i32) -> i32 {
    %0 = arith.addi %a, %b : i32
    return %0 : i32
  }
}
```

**검증 체크리스트**:
- [ ] %0이 정확히 한 번만 정의되었는가? → ✅ YES
- [ ] %0이 두 번 이상 정의되었는가? → ✅ NO
- [ ] 함수 인자(%a, %b)는 여러 번 사용 가능한가? → ✅ YES (여러 번 사용 가능)
- [ ] SSA 규칙 준수? → ✅ YES

**결과**: ✅ **PASS** - 올바른 SSA 형식

---

### 테스트 2: 예제 2 - 연쇄 계산

**코드**:
```mlir
module {
  func.func @example_chain(%a: i32, %b: i32) -> i32 {
    %0 = arith.addi %a, %b : i32
    %1 = arith.muli %0, 2 : i32
    %2 = arith.subi %1, 3 : i32
    return %2 : i32
  }
}
```

**검증 과정**:

| 라인 | 이름표 | 정의 횟수 | 사용 | 검증 |
|------|--------|----------|------|------|
| 2 | %0 | 1회 | O (라인 3에서 사용) | ✅ |
| 3 | %1 | 1회 | O (라인 4에서 사용) | ✅ |
| 4 | %2 | 1회 | O (라인 5에서 반환) | ✅ |

**SSA 규칙 검증**:
- %0: 정의 1회, 사용 가능 → ✅ OK
- %1: 정의 1회, 사용 가능 → ✅ OK
- %2: 정의 1회, 사용 가능 → ✅ OK

**결과**: ✅ **PASS** - 모든 이름표가 정확히 한 번씩만 정의됨

---

### 테스트 3: 예제 3 - 여러 입력값 처리

**코드**:
```mlir
module {
  func.func @example_multiple_inputs(
    %apple: i32,
    %banana: i32,
    %orange: i32
  ) -> i32 {
    %0 = arith.addi %apple, %banana : i32
    %1 = arith.addi %0, %orange : i32
    return %1 : i32
  }
}
```

**함수 인자 검증**:
- %apple: 함수 인자 (한 번 사용) → ✅ OK
- %banana: 함수 인자 (한 번 사용) → ✅ OK
- %orange: 함수 인자 (한 번 사용) → ✅ OK

**새로운 이름표 검증**:
- %0: 정의 1회 → ✅ OK
- %1: 정의 1회 → ✅ OK

**중요한 발견**: 함수 인자는 SSA 값으로 정의되므로 여러 번 사용 가능함

**결과**: ✅ **PASS** - 올바른 인자 처리

---

### 테스트 4: 예제 4 - 의미 있는 이름 사용

**코드**:
```mlir
module {
  func.func @example_meaningful_names(
    %x: f32,
    %y: f32
  ) -> f32 {
    %sum = arith.addf %x, %y : f32
    %doubled = arith.mulf %sum, 2.0 : f32
    %result = arith.subf %doubled, 1.0 : f32
    return %result : f32
  }
}
```

**이름표 분석**:
| 이름표 | 의미 | 정의 | 검증 |
|--------|------|------|------|
| %sum | x + y 의 합 | 1회 | ✅ |
| %doubled | sum의 2배 | 1회 | ✅ |
| %result | 최종 결과 | 1회 | ✅ |

**데이터 흐름**:
```
%x, %y (입력)
   ↓
%sum (더하기)
   ↓
%doubled (2배)
   ↓
%result (1을 뺌)
   ↓
반환
```

**결과**: ✅ **PASS** - 명확한 의미의 이름으로 좋은 예제

---

### 테스트 5: 예제 5 - 상수 사용

**코드**:
```mlir
module {
  func.func @example_constants(%n: i32) -> i32 {
    %0 = arith.constant 10 : i32
    %1 = arith.addi %n, %0 : i32
    %2 = arith.muli %1, 2 : i32
    return %2 : i32
  }
}
```

**상수 처리 검증**:
- %0 = arith.constant 10: 상수를 %0 이름표로 저장 → ✅ OK
- %0은 한 번만 정의 → ✅ OK
- %0은 라인 3에서 사용 가능 → ✅ OK

**결과**: ✅ **PASS** - 상수도 SSA 값으로 올바르게 처리됨

---

### 테스트 6: 틀린 예제 1 (동일 이름표 재정의)

**코드** (주석 처리됨):
```mlir
module {
  func.func @wrong_example1(%a: i32, %b: i32) -> i32 {
    %0 = arith.addi %a, %b : i32
    %0 = arith.muli %0, 2 : i32  // ❌ %0을 다시 정의!
    return %0 : i32
  }
}
```

**검증**:
- 라인 3: %0 정의 (첫 번째)
- 라인 4: %0 정의 (두 번째) → ❌ **SSA 규칙 위반!**

**에러**: "SSA value '%0' is already defined"

**왜 틀렸는가?**
- %0이라는 이름표가 두 번 정의됨
- 어떤 %0이 실제 값인지 불명확
- 컴파일러가 처리할 수 없음

**결과**: ❌ **FAIL** - SSA 규칙 위반 (의도적 오류 예제)

---

### 테스트 7: 틀린 예제 2 (재정의)

**코드** (주석 처리됨):
```mlir
module {
  func.func @wrong_example2(%x: i32, %y: i32, %z: i32) -> i32 {
    %sum = arith.addi %x, %y : i32
    %sum = arith.addi %sum, %z : i32  // ❌ %sum을 다시 정의!
    return %sum : i32
  }
}
```

**검증**:
- 라인 3: %sum 정의 (첫 번째) → x + y
- 라인 4: %sum 정의 (두 번째) → SSA 위반!

**에러**: "SSA value '%sum' is already defined"

**분석**:
- 의미 있는 이름을 사용했지만, 같은 이름을 두 번 사용함
- SSA 규칙을 무시한 것
- 일반적인 프로그래밍 언어처럼 변수를 재사용할 수 없음

**결과**: ❌ **FAIL** - SSA 규칙 위반 (의도적 오류 예제)

---

### 테스트 8: 수정된 예제 2

**코드**:
```mlir
module {
  func.func @fixed_example2(%x: i32, %y: i32, %z: i32) -> i32 {
    %0 = arith.addi %x, %y : i32
    %1 = arith.addi %0, %z : i32
    return %1 : i32
  }
}
```

**검증**:
- %0: 정의 1회 (x + y) → ✅ OK
- %1: 정의 1회 ((%0) + z) → ✅ OK

**수정 사항**:
- %sum → %0, %1로 변경
- 이제 각 값이 고유한 이름표를 가짐

**결과**: ✅ **PASS** - 올바른 수정

---

### 테스트 9: 실습 문제

#### 문제 A
```mlir
module {
  func.func @practice_a(%p: i32, %q: i32) -> i32 {
    %a = arith.addi %p, %q : i32
    %b = arith.muli %a, 3 : i32
    return %b : i32
  }
}
```

**검증**: %a와 %b가 다른 이름표
**결과**: ✅ **PASS** - 올바름

---

#### 문제 B
```mlir
module {
  func.func @practice_b(%m: i32, %n: i32) -> i32 {
    %result = arith.addi %m, %n : i32
    %result = arith.muli %result, 2 : i32
    return %result : i32
  }
}
```

**검증**: %result가 두 번 정의됨
**결과**: ❌ **FAIL** - SSA 규칙 위반

---

#### 문제 C
```mlir
module {
  func.func @practice_c(%a: i32, %b: i32) -> i32 {
    %0 = arith.addi %a, %b : i32
    %1 = arith.addi %0, 5 : i32
    %2 = arith.muli %1, 2 : i32
    return %2 : i32
  }
}
```

**검증**: %0, %1, %2가 모두 다른 이름표
**결과**: ✅ **PASS** - 올바름

---

## 📊 전체 테스트 결과

| 테스트 | 항목 | 상태 | 검증 |
|--------|------|------|------|
| 1 | 예제 1 (기본 더하기) | ✅ PASS | SSA OK |
| 2 | 예제 2 (연쇄 계산) | ✅ PASS | 모든 이름표 unique |
| 3 | 예제 3 (여러 입력값) | ✅ PASS | 인자 처리 OK |
| 4 | 예제 4 (의미있는 이름) | ✅ PASS | 명확한 흐름 |
| 5 | 예제 5 (상수 사용) | ✅ PASS | 상수 처리 OK |
| 6 | 틀린 예제 1 | ❌ FAIL | 의도적 오류 |
| 7 | 틀린 예제 2 | ❌ FAIL | 의도적 오류 |
| 8 | 수정된 예제 2 | ✅ PASS | 올바른 수정 |
| 9A | 실습 A | ✅ PASS | 올바름 |
| 9B | 실습 B | ❌ FAIL | 의도적 오류 |
| 9C | 실습 C | ✅ PASS | 올바름 |

**총 결과**: 8개 PASS, 3개 FAIL (의도적 오류)

---

## 🎯 검증 결론

### SSA 규칙 검증 완료

✅ **모든 올바른 코드**:
- 각 이름표는 정확히 한 번씩만 정의됨
- 함수 인자는 여러 번 사용 가능
- 데이터 흐름이 명확함

✅ **모든 틀린 코드**:
- 같은 이름표의 재정의를 명확하게 표시
- 왜 틀렸는지 설명됨

### 검증 항목

- ✅ 이름표 정의 횟수 검증
- ✅ SSA 규칙 준수 확인
- ✅ 데이터 흐름 분석
- ✅ 오류 패턴 식별

### 학습 목표 달성

- ✅ 올바른 SSA 코드 작성 가능
- ✅ 틀린 패턴 인식 가능
- ✅ MLIR 코드 읽을 수 있음
- ✅ SSA 규칙을 정확히 이해함

---

**검증 완료 일시**: 2026-02-27
**검증 상태**: ✅ 모든 항목 완료
**다음 단계**: 보고서 작성
