// ============================================
// 초등 1.2: Dialect(도구 상자)와 Operation(도구)
// ============================================

// 파일 설명:
// - Dialect.도구 형식의 올바른 예제들 (✅)
// - 틀린 예제들 (❌)
// - 여러 Dialect를 함께 사용하는 예제
// - 실습 문제

// ============================================
// 예제 1: arith Dialect - 정수 연산 (올바른 코드)
// ============================================

module {
  func.func @integer_arithmetic(%a: i32, %b: i32) -> i32 {
    // ✅ arith (산술 상자)의 addi (정수 더하기 도구)
    %0 = arith.addi %a, %b : i32

    // ✅ arith (산술 상자)의 muli (정수 곱하기 도구)
    %1 = arith.muli %0, 2 : i32

    // ✅ arith (산술 상자)의 subi (정수 빼기 도구)
    %2 = arith.subi %1, 3 : i32

    // ✅ func (함수 상자)의 return (반환 도구)
    func.return %2 : i32
  }
}

// 분석:
// ✅ arith.addi - 형식 정확함: "상자.도구"
// ✅ arith.muli - Dialect가 명시됨
// ✅ arith.subi - 마침표로 연결됨
// ✅ func.return - 다른 Dialect도 함께 사용 가능


// ============================================
// 예제 2: arith Dialect - 실수 연산 (올바른 코드)
// ============================================

module {
  func.func @float_arithmetic(%x: f32, %y: f32) -> f32 {
    // ✅ arith (산술 상자)의 addf (실수 더하기 도구)
    %0 = arith.addf %x, %y : f32

    // ✅ arith (산술 상자)의 mulf (실수 곱하기 도구)
    %1 = arith.mulf %0, 2.5 : f32

    // ✅ arith (산술 상자)의 divf (실수 나누기 도구)
    %2 = arith.divf %1, 1.5 : f32

    func.return %2 : f32
  }
}

// 분석:
// ✅ addf vs addi 구분 - 정수와 실수 구분
// ✅ mulf vs muli 구분 - 타입에 맞는 도구
// ✅ divf - 실수 나누기 전용 도구
// ✅ Dialect가 명확하게 표시됨


// ============================================
// 예제 3: 여러 Dialect를 함께 사용 (올바른 코드)
// ============================================

module {
  func.func @mixed_dialects(%a: i32, %b: i32, %x: f32) -> i32 {
    // ✅ arith Dialect 사용 - 정수 연산
    %0 = arith.addi %a, %b : i32    // 정수 더하기
    %1 = arith.muli %0, 3 : i32     // 정수 곱하기

    // ✅ func Dialect 사용 - 반환
    func.return %1 : i32
  }
}

// 분석:
// ✅ 한 함수 안에서 여러 Dialect 사용 가능
// ✅ 각 도구가 자신의 Dialect 표시
// ✅ 혼합해서 사용해도 형식이 명확함


// ============================================
// 예제 4: arith Dialect - 모든 도구 (올바른 코드)
// ============================================

module {
  func.func @all_arith_operations(%a: i32, %b: i32) -> i32 {
    // ✅ 정수 더하기
    %0 = arith.addi %a, %b : i32

    // ✅ 정수 빼기
    %1 = arith.subi %0, 1 : i32

    // ✅ 정수 곱하기
    %2 = arith.muli %1, 2 : i32

    // ✅ 정수 나누기
    %3 = arith.divi_signed %2, 2 : i32

    func.return %3 : i32
  }
}

// 분석:
// ✅ 모두 "arith." 접두어 가짐
// ✅ 모두 마침표로 연결됨
// ✅ 각 도구의 이름이 명확함 (add, sub, mul, div)


// ============================================
// 예제 5: func Dialect - 함수 정의 (올바른 코드)
// ============================================

module {
  // ✅ func.func - 함수 정의 도구
  func.func @multiply(%x: i32, %y: i32) -> i32 {
    // ✅ arith.muli - 곱하기 도구 사용
    %0 = arith.muli %x, %y : i32

    // ✅ func.return - 반환 도구
    func.return %0 : i32
  }

  // ✅ 또 다른 함수
  func.func @add_then_multiply(%a: i32, %b: i32, %c: i32) -> i32 {
    // ✅ arith.addi - 더하기
    %0 = arith.addi %a, %b : i32

    // ✅ arith.muli - 곱하기
    %1 = arith.muli %0, %c : i32

    // ✅ func.return - 반환
    func.return %1 : i32
  }
}

// 분석:
// ✅ func.func 형식 정확함
// ✅ func.return 형식 정확함
// ✅ 여러 함수를 한 모듈에 정의 가능
// ✅ 함수 안에서 arith Dialect 사용


// ============================================
// 예제 6: Dialect와 도구의 조합 (올바른 코드)
// ============================================

module {
  func.func @complex_calculation(%p: i32, %q: i32, %r: i32) -> i32 {
    // ✅ 더하기 (arith Dialect)
    %step1 = arith.addi %p, %q : i32

    // ✅ 곱하기 (arith Dialect)
    %step2 = arith.muli %step1, %r : i32

    // ✅ 상수 추가
    %const = arith.constant 100 : i32

    // ✅ 더하기 (arith Dialect)
    %step3 = arith.addi %step2, %const : i32

    // ✅ 반환 (func Dialect)
    func.return %step3 : i32
  }
}

// 분석:
// ✅ arith.constant - 상수 정의
// ✅ 의미 있는 이름표 사용 (step1, step2, step3, const)
// ✅ Dialect와 도구가 명확히 분리됨


// ============================================
// ❌ 틀린 예제 1: Dialect 생략
// ============================================

// 주석 처리 (실제로는 에러가 남):
/*
module {
  func.func @wrong_example1(%a: i32, %b: i32) -> i32 {
    // ❌ addi만 쓰고 Dialect를 생략!
    %0 = addi %a, %b : i32
    return %0 : i32
  }
}
*/

// 왜 틀렸나?
// ❌ "addi" 도구가 어느 Dialect의 도구인지 불명확
// ❌ 컴파일러가 어디서 addi를 찾아야 할지 모름
// ❌ arith, some_other_dialect 등 여러 곳에 addi가 있을 수 있음

// 올바른 수정:
// ✅ %0 = arith.addi %a, %b : i32


// ============================================
// ❌ 틀린 예제 2: 잘못된 Dialect 이름
// ============================================

// 주석 처리:
/*
module {
  func.func @wrong_example2(%x: f32, %y: f32) -> f32 {
    // ❌ "math" Dialect는 없는 상자!
    %0 = math.addf %x, %y : f32
    return %0 : f32
  }
}
*/

// 왜 틀렸나?
// ❌ "math" Dialect는 MLIR에 없음
// ❌ 실제로는 "arith" Dialect
// ❌ 잘못된 상자 이름

// 올바른 수정:
// ✅ %0 = arith.addf %x, %y : f32


// ============================================
// ❌ 틀린 예제 3: 잘못된 도구 이름
// ============================================

// 주석 처리:
/*
module {
  func.func @wrong_example3(%a: i32, %b: i32) -> i32 {
    // ❌ "add" 도구는 없음 (addi 또는 addf여야 함)
    %0 = arith.add %a, %b : i32
    return %0 : i32
  }
}
*/

// 왜 틀렸나?
// ❌ arith.add는 없는 도구
// ❌ 정수면 arith.addi, 실수면 arith.addf
// ❌ 타입에 맞는 정확한 도구 이름 필요

// 올바른 수정:
// ✅ %0 = arith.addi %a, %b : i32


// ============================================
// ❌ 틀린 예제 4: Dialect와 도구 모두 틀림
// ============================================

// 주석 처리:
/*
module {
  func.func @wrong_example4(%x: f32) -> f32 {
    // ❌ 상자도 틀리고(calc), 도구도 틀림(plus)
    %0 = calc.plus %x, 1.0 : f32
    return %0 : f32
  }
}
*/

// 왜 틀렸나?
// ❌ "calc" Dialect는 없음
// ❌ "plus" 도구는 없음 (addf여야 함)
// ❌ 상자 이름과 도구 이름 모두 틀림

// 올바른 수정:
// ✅ %0 = arith.addf %x, 1.0 : f32


// ============================================
// ❌ 틀린 예제 5: 함수 정의 형식 틀림
// ============================================

// 주석 처리:
/*
module {
  // ❌ "function" Dialect는 없음 (func여야 함)
  function.func @wrong(%a: i32) -> i32 {
    %0 = arith.addi %a, 1 : i32
    return %0 : i32  // ❌ func.return이어야 함
  }
}
*/

// 왜 틀렸나?
// ❌ function.func는 틀린 형식 (func.func 맞음)
// ❌ return은 func.return이어야 함

// 올바른 수정:
// ✅ func.func @correct(%a: i32) -> i32 {
// ✅   func.return %0 : i32
// ✅ }


// ============================================
// 올바른 수정: 틀린 예제 4 수정
// ============================================

module {
  func.func @fixed_example4(%x: f32) -> f32 {
    // 수정: 올바른 Dialect.도구 형식 사용
    %0 = arith.addf %x, 1.0 : f32
    func.return %0 : f32
  }
}

// 수정 사항:
// ✅ "calc" → "arith" (올바른 상자)
// ✅ "plus" → "addf" (올바른 도구, 실수 더하기)
// ✅ "return" → "func.return" (올바른 형식)


// ============================================
// 올바른 수정: 틀린 예제 5 수정
// ============================================

module {
  // 수정: func.func 형식 사용
  func.func @fixed_example5(%a: i32) -> i32 {
    %0 = arith.addi %a, 1 : i32
    func.return %0 : i32  // 올바른 형식
  }
}

// 수정 사항:
// ✅ "function" → "func" (올바른 Dialect)
// ✅ "return" → "func.return" (올바른 형식)


// ============================================
// 실습: 다음 코드가 올바른가?
// ============================================

// 문제 A: Dialect와 도구가 명확한가?
/*
module {
  func.func @practice_a(%p: i32, %q: i32) -> i32 {
    %a = arith.addi %p, %q : i32
    %b = arith.muli %a, 3 : i32
    func.return %b : i32
  }
}
*/
// 답: ✅ 올바름
// 이유: 모든 도구가 Dialect.도구 형식
// - arith.addi (O)
// - arith.muli (O)
// - func.return (O)


// 문제 B: 틀린 부분을 찾아보세요
/*
module {
  func.func @practice_b(%m: i32, %n: i32) -> i32 {
    %result = addi %m, %n : i32  // ← 주목!
    %final = arith.muli %result, 2 : i32
    func.return %final : i32
  }
}
*/
// 답: ❌ 틀림
// 틀린 부분: "addi" (Dialect 생략!)
// 올바른 수정: "arith.addi"


// 문제 C: 여러 Dialect를 함께 사용 (올바른가?)
/*
module {
  func.func @practice_c(%a: i32, %b: i32, %c: i32) -> i32 {
    %0 = arith.addi %a, %b : i32
    %1 = arith.muli %0, %c : i32
    %2 = arith.addi %1, 1 : i32
    func.return %2 : i32
  }
}
*/
// 답: ✅ 올바름
// 이유: 모든 도구가 명확한 Dialect 표시
// - arith.addi (3번 사용 - 모두 명확함)
// - arith.muli (1번 사용 - 명확함)
// - func.return (명확함)


// 문제 D: 잘못된 Dialect 찾기
/*
module {
  func.func @practice_d(%x: f32, %y: f32) -> f32 {
    %0 = arith.add %x, %y : f32  // ← 주목!
    func.return %0 : f32
  }
}
*/
// 답: ❌ 틀림
// 틀린 부분: "arith.add" (도구 이름 부정확)
// 올바른 수정: "arith.addf" (실수 더하기)


// ============================================
// 정리: Dialect와 Operation의 핵심
// ============================================

// ✅ 올바른 패턴:
//    상자이름.도구이름 (%입력값들) : 타입
//
//    예:
//    arith.addi %a, %b : i32
//    arith.addf %x, %y : f32
//    func.func @name(...) -> type { ... }
//    func.return %value : type
//    memref.alloc() : memref<10xi32>

// ❌ 틀린 패턴:
//    도구이름만 사용
//    잘못된 Dialect 이름
//    잘못된 도구 이름
//    Dialect를 생략

// 핵심:
// - Dialect는 도구 상자
// - Operation은 실제 도구
// - 마침표(.)로 상자와 도구를 연결
// - 형식: 상자이름.도구이름
// - 컴파일러가 올바른 도구를 찾도록 도와줌

// ============================================

