# 📦 [대학원 4.3] 설계도에 생명 불어넣기: C++ 통합과 빌드 시스템(CMake)

> **MLIR 대학원의 세 번째 단계: 실전 시스템 구축**
>
> "저장 필수. 너는 기록이 증명이다."
>
> TableGen으로 설계한 명세서(.td)와 최적화 규칙들을
> 실제 동작하는 바이너리 파일로 뽑아낼 차례입니다.
>
> 대학원 연구실에서 본인만의 컴파일러를 관리하기 위한
> **'뼈대'**를 세우는 작업입니다.

---

## 🎯 오늘 배울 것

한 가지 핵심 개념입니다:

> **"TableGen으로 생성된 코드는 C++ 프로젝트에 #include 되어 실제 기능을 수행한다."**
>
> **"CMake는 이 모든 변환 과정과 컴파일 과정을 조율하는 설계도 역할을 한다."**

---

## 1️⃣ C++ Integration (자동 생성 코드 연결)

### 문제: TableGen이 생성한 코드를 어떻게 사용할까?

```
TableGen이 생성하는 것:
├─ MyDialect.h.inc      (Operation 정의)
├─ MyDialect.cpp.inc    (구현)
└─ MyDialectOps.h.inc   (Op 클래스들)

당신의 C++ 코드:
├─ MyDialect.h          (헤더)
├─ MyDialect.cpp        (구현)
└─ ???

연결 방법?
```

### 해결책 1: Header Include

```cpp
// file: MyDialect.h (당신이 작성)
#ifndef MYDIALECT_H
#define MYDIALECT_H

#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"

namespace mlir {
namespace my {

// TableGen이 생성한 코드를 불러오기
#define GET_OP_CLASSES
#include "MyDialectOps.h.inc"

} // namespace my
} // namespace mlir

#endif
```

**의미**:
```
#define GET_OP_CLASSES
  → "Operation 클래스 정의 부분만 가져와"

#include "MyDialectOps.h.inc"
  → TableGen이 생성한 파일을 여기에 삽입
```

### 해결책 2: Registry 등록

```cpp
// file: MyDialect.cpp (당신이 작성)
#include "MyDialect.h"

namespace mlir {
namespace my {

// Dialect 정의
class MyDialect : public Dialect {
public:
  explicit MyDialect(MLIRContext *context)
      : Dialect(getDialectNamespace(), context, TypeID::get<MyDialect>()) {
    // Operation들을 이 Dialect에 등록
    addOperations<
#define GET_OP_LIST
#include "MyDialectOps.cpp.inc"
    >();
  }

  static StringRef getDialectNamespace() { return "my"; }
};

} // namespace my
} // namespace mlir

// MLIR 시스템에 이 Dialect 등록
REGISTER_DIALECT(MyDialect);
```

**의미**:
```
GET_OP_LIST
  → "모든 Operation 목록을 가져와"

addOperations<...>()
  → "이 Dialect에 등록해"

REGISTER_DIALECT
  → "MLIR 전체 시스템에 알려줘"
```

### Include Guard 패턴

```cpp
// MyDialect.h 구조 예시
#ifndef MYDIALECT_H
#define MYDIALECT_H

// Step 1: 의존성 포함
#include "mlir/IR/Dialect.h"

namespace mlir::my {

// Step 2: Dialect 클래스 선언 (전방 선언)
class MyDialect;

// Step 3: TableGen 생성 코드 - 정의 부분
#define GET_OP_CLASSES
#include "MyDialectOps.h.inc"

// Step 4: Custom Dialect 정의
class MyDialect : public Dialect {
public:
  explicit MyDialect(MLIRContext *context);
  static StringRef getDialectNamespace() { return "my"; }
};

} // namespace mlir::my

#endif
```

---

## 2️⃣ CMake: 빌드 시스템 설계

### 기본 개념

```
CMakeLists.txt은 "빌드 설계도"입니다:

소스 코드들 (*.cpp, *.td)
        ↓
   CMakeLists.txt (설계도)
        ↓
    컴파일 과정
        ↓
   실행 파일 (바이너리)
```

### 기본 구조

```cmake
# CMakeLists.txt

# 1️⃣ 최소 CMake 버전 명시
cmake_minimum_required(VERSION 3.16)

# 2️⃣ 프로젝트 정보
project(MyDialectProject)

# 3️⃣ MLIR 찾기
find_package(MLIR REQUIRED CONFIG)

# 4️⃣ 라이브러리 생성
add_library(MyDialect
  SHARED
  lib/MyDialect.cpp
  lib/MyDialectOps.cpp
)

# 5️⃣ 포함 디렉토리 설정
target_include_directories(MyDialect
  PUBLIC
  ${MLIR_INCLUDE_DIRS}
  ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# 6️⃣ 링크 라이브러리
target_link_libraries(MyDialect
  PRIVATE
  MLIRDialect
  MLIRIRDialect
  MLIRSupport
)
```

### TableGen 규칙 추가

```cmake
# TableGen 코드 생성 규칙 추가
add_mlir_dialect_library(MyDialectOps
  MyDialectOps.td
  DEPENDS
  DialectBase
)

# 이 규칙이 하는 일:
# 1. MyDialectOps.td 파일을 읽음
# 2. TableGen을 실행하여 .h.inc와 .cpp.inc 파일 생성
# 3. 생성된 파일을 include 디렉토리에 배치
# 4. C++ 컴파일이 이 파일들을 사용하도록 설정
```

### 실행 파일 생성

```cmake
# 나만의 mlir-opt 같은 도구 만들기
add_executable(my-mlir-opt
  tools/my-mlir-opt.cpp
)

target_link_libraries(my-mlir-opt
  PRIVATE
  MyDialect
  MLIROptMain
  MLIRSupport
)
```

---

## 3️⃣ 프로젝트 구조 (대학원 표준 템플릿)

### 디렉토리 구조

```
my_dialect_project/
├── CMakeLists.txt          ← 최상위 빌드 설정
├── include/
│   └── my/
│       ├── MyDialect.h     ← Dialect 헤더
│       └── MyDialectOps.td ← TableGen 명세 (핵심!)
├── lib/
│   ├── CMakeLists.txt      ← 라이브러리 빌드 설정
│   ├── MyDialect.cpp       ← Dialect 구현
│   └── MyDialectOps.cpp    ← Operation 구현
├── tools/
│   ├── CMakeLists.txt
│   └── my-mlir-opt.cpp     ← 실행 파일 (사용자 도구)
└── test/
    ├── CMakeLists.txt
    └── my-dialect-test.mlir ← 테스트 코드
```

### 각 파일의 역할

```
include/my/MyDialect.h
  → 당신이 직접 작성
  → Dialect와 Operation 인터페이스 정의
  → TableGen 생성 코드를 #include

include/my/MyDialectOps.td
  → TableGen 명세 (4.1, 4.2에서 배운 것)
  → def MyAddOp : MyDialect_Op<...>
  → def FusionRule : Pat<...>

lib/MyDialect.cpp
  → 당신이 직접 작성
  → Dialect 등록, Registry 설정
  → 커스텀 검증/분석 로직

lib/MyDialectOps.cpp
  → TableGen이 대부분 생성
  → 당신은 커스텀 부분만 추가

tools/my-mlir-opt.cpp
  → 당신의 Dialect를 사용하는 도구
  → mlir-opt 같은 기능 제공

test/my-dialect-test.mlir
  → 당신의 Operation/규칙 테스트
  → 실제로 작동하는지 검증
```

---

## 4️⃣ 빌드 과정 상세 분석

### Step 1: CMake 설정

```bash
$ mkdir build
$ cd build
$ cmake ..
```

**내부적으로 일어나는 일**:
```
CMakeLists.txt 읽음
  ↓
MLIR 찾기 (find_package(MLIR))
  ↓
TableGen 위치 파악
  ↓
컴파일 규칙 생성
```

### Step 2: TableGen 코드 생성

```bash
$ make MyDialectOps_inc_gen
```

**내부적으로 일어나는 일**:
```
MyDialectOps.td 읽음 (Operation 정의)
  ↓
TableGen 도구 실행
  ↓
MyDialectOps.h.inc 생성 (Op 클래스)
  ↓
MyDialectOps.cpp.inc 생성 (구현)
  ↓
include/ 디렉토리에 배치
```

### Step 3: C++ 컴파일

```bash
$ make MyDialect
```

**내부적으로 일어나는 일**:
```
MyDialect.h 컴파일
  ├─ #include "MyDialectOps.h.inc" 실행
  └─ → TableGen이 생성한 Operation 클래스 로드

MyDialect.cpp 컴파일
  ├─ #include "MyDialectOps.cpp.inc" 실행
  └─ → TableGen이 생성한 구현 코드 로드

MyDialectOps.cpp 컴파일
  └─ 커스텀 구현 추가

모두 링크 (Linking)
  └─ libMyDialect.so 생성
```

### Step 4: 실행 파일 생성

```bash
$ make my-mlir-opt
```

**내부적으로 일어나는 일**:
```
my-mlir-opt.cpp 컴파일
  ├─ MyDialect 라이브러리 링크
  ├─ MLIR 코어 링크
  └─ 기타 의존성 링크

실행 파일 생성
  └─ my-mlir-opt (바이너리)
```

### 전체 빌드 흐름 (다이어그램)

```
MyDialectOps.td (당신이 작성)
    ↓
[mlir_tablegen]  (CMake가 TableGen 실행)
    ↓
MyDialectOps.h.inc (생성)
MyDialectOps.cpp.inc (생성)
    ↓
MyDialect.h (당신의 코드)
  └─ #include "MyDialectOps.h.inc"
    ↓
MyDialect.cpp (당신의 코드)
  └─ #include "MyDialectOps.cpp.inc"
    ↓
[C++ 컴파일러]
    ↓
libMyDialect.so (라이브러리)
    ↓
my-mlir-opt.cpp (당신의 도구)
    ├─ libMyDialect.so 링크
    ├─ MLIR 코어 링크
    └─ ...
    ↓
[C++ 컴파일러 + 링커]
    ↓
my-mlir-opt (실행 파일!) ✅
```

---

## 5️⃣ 실전: 빌드 에러 해결

### 시나리오: 새로운 Operation 추가 후 컴파일 에러

```
에러 메시지:
  "error: undefined reference to `MyNewOp::build`"

원인이 뭘까?
```

### 원인 분석 체크리스트

```
1️⃣ .td 파일 확인
  ├─ 오타가 없나? (def MyNewOp vs def MyNewOP)
  ├─ Syntax 맞나? (괄호, 세미콜론)
  └─ arguments/results 정의됐나?

2️⃣ CMakeLists.txt 확인
  ├─ mlir_tablegen이 MyDialectOps.td를 처리하나?
  ├─ 생성된 .inc 파일 위치가 맞나?
  └─ #include 경로가 맞나?

3️⃣ C++ 코드 확인
  ├─ #define GET_OP_CLASSES 했나?
  ├─ #include "MyDialectOps.h.inc" 했나?
  └─ 순서가 맞나? (define 먼저, include 나중)
```

### 실제 해결 과정

```
증상: "undefined reference to `MyNewOp::build`"

Step 1: .td 파일 확인
  def MyNewOp : MyDialect_Op<"my_new"> {
    let arguments = (ins F32:$x);
    let results = (outs F32:$y);
  }
  ✓ 문법 OK

Step 2: CMakeLists.txt 확인
  add_mlir_dialect_library(MyDialectOps
    include/my/MyDialectOps.td  ← 경로 확인!
    ...
  )
  ✓ 설정 OK

Step 3: C++ 코드 확인
  // MyDialect.h
  #define GET_OP_CLASSES
  #include "MyDialectOps.h.inc"  ← 이 순서!
  ✓ 순서 OK

Step 4: 빌드 재시도
  $ rm -rf build
  $ mkdir build && cd build
  $ cmake .. && make
  ✓ 성공!

해결!
```

### 일반적인 빌드 에러와 해결책

```
1. "cannot find MyDialectOps.h.inc"
   → CMake가 TableGen 코드를 안 생성했다
   → CMakeLists.txt에서 mlir_tablegen 설정 확인

2. "undefined reference to Operation"
   → #include 순서가 잘못되었다
   → #define 먼저, #include 나중 순서 확인

3. "linking error with MLIR"
   → MLIR 라이브러리를 링크 안 했다
   → target_link_libraries에 MLIRCore 등 추가

4. "TableGen parsing error"
   → .td 파일 문법 오류
   → def 블록의 괄호, 세미콜론 확인
```

---

## 6️⃣ 실전 CMakeLists.txt 예제

### 완전한 프로젝트 예제

```cmake
# CMakeLists.txt (최상위)

cmake_minimum_required(VERSION 3.16)
project(MyDialectProject)

# MLIR 찾기
find_package(MLIR REQUIRED CONFIG)
set(LLVM_RUNTIME_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/bin)

# include 디렉토리 설정
include_directories(${LLVM_INCLUDE_DIRS})
include_directories(${MLIR_INCLUDE_DIRS})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/include)

# 라이브러리 빌드
add_subdirectory(lib)

# 도구 빌드
add_subdirectory(tools)

# 테스트
enable_testing()
add_subdirectory(test)
```

### lib/CMakeLists.txt

```cmake
# TableGen 코드 생성
set(LLVM_TARGET_DEFINITIONS ../include/my/MyDialectOps.td)

mlir_tablegen(MyDialectOps.h.inc -gen-op-defs)
mlir_tablegen(MyDialectOps.cpp.inc -gen-op-impl)

add_public_tablegen_target(MyDialectOpsIncGen)

# 라이브러리 생성
add_mlir_dialect_library(MyDialect
  MyDialect.cpp
  DEPENDS
  MyDialectOpsIncGen
)

target_link_libraries(MyDialect
  PRIVATE
  MLIRDialect
  MLIRIRDialect
)
```

### tools/CMakeLists.txt

```cmake
# 도구 생성
add_executable(my-mlir-opt
  my-mlir-opt.cpp
)

target_link_libraries(my-mlir-opt
  PRIVATE
  MyDialect
  MLIROptMain
  MLIRSupport
  LLVMSupport
)
```

---

## 7️⃣ 실행 예제

### 빌드 및 실행

```bash
# 1️⃣ 빌드 디렉토리 생성
$ mkdir build && cd build

# 2️⃣ CMake 설정 (TableGen 코드 생성도 포함)
$ cmake ..

# 3️⃣ 컴파일
$ make

# 4️⃣ 실행
$ ./bin/my-mlir-opt ../test/my-dialect-test.mlir

# 출력 예:
# module {
#   %0 = my.add %arg0, %arg1 : f32
#   %1 = my.matmul_relu %A, %B : tensor<4x4xf32>
# }
```

### 빌드 출력 분석

```
[30%] Generating MyDialectOps.h.inc
  ← TableGen이 .td 파일 처리

[35%] Generating MyDialectOps.cpp.inc
  ← TableGen이 구현 코드 생성

[50%] Building CXX object lib/CMakeFiles/...
  ← C++ 컴파일 (생성된 코드 포함)

[75%] Linking CXX executable bin/my-mlir-opt
  ← 링킹 (모든 객체 파일 연결)

[100%] Built target my-mlir-opt
  ← 완성!
```

---

## 8️⃣ 대학원 4.3 핵심 정리

### C++ Integration의 핵심

```
TableGen 생성 코드
    ↓
#include "MyDialectOps.h.inc"
    ↓
Operation 클래스 로드
    ↓
Dialect에 등록
    ↓
MLIR 시스템 인식
```

### CMake의 역할

```
CMakeLists.txt
    ↓
"이런 순서로 빌드해줘"를 지정
    ↓
1. TableGen 실행
2. C++ 컴파일
3. 링킹
    ↓
최종 바이너리
```

### 설계 체크리스트

```
새로운 Project를 만들 때:

□ CMakeLists.txt 작성
  └─ find_package(MLIR)
  └─ mlir_tablegen 규칙
  └─ add_library, add_executable

□ include/my/MyDialectOps.td 작성
  └─ def MyOp : MyDialect_Op<...>

□ include/my/MyDialect.h 작성
  └─ #define GET_OP_CLASSES
  └─ #include "MyDialectOps.h.inc"

□ lib/MyDialect.cpp 작성
  └─ Dialect 정의
  └─ REGISTER_DIALECT

□ tools/my-mlir-opt.cpp 작성
  └─ MLIR 옵션 파서
  └─ Dialect 등록

□ test/test.mlir 작성
  └─ 테스트 코드

모두 OK면 빌드!
```

---

## 9️⃣ 대학원 4.3 기록 (증명)

> **"TableGen으로 생성된 코드는 C++ 프로젝트에 #include 되어 실제 기능을 수행한다."**
>
> **"CMake는 이 모든 변환 과정과 컴파일 과정을 조율하는 설계도 역할을 한다."**
>
> **C++ Integration의 핵심:**
> - #define GET_OP_CLASSES
> - #include "MyDialectOps.h.inc"
> - REGISTER_DIALECT(MyDialect)
>
> **CMake의 역할:**
> - mlir_tablegen: TableGen 코드 생성
> - add_mlir_dialect_library: 라이브러리 생성
> - target_link_libraries: 의존성 연결
>
> **빌드 에러 해결:**
> - TableGen 설정 확인 (CMakeLists.txt)
> - Include 순서 확인 (C++ 헤더)
> - 의존성 확인 (target_link_libraries)
>
> 이제 당신은 **실전 MLIR 프로젝트 관리자**입니다!

---

## 🔟 다음 단계: 대학원 4.4

### 4.4: 커스텀 Pass 구현 (C++)

```
지금까지:
- 4.1: Operation 설계 (TableGen)
- 4.2: 최적화 규칙 (DRR)
- 4.3: 빌드 시스템 (CMake + C++) ← 현위치

다음:
- 4.4: 복잡한 알고리즘 구현 (C++ Pass)

DRR로 해결 안 되는 것들:
✅ 복잡한 패턴 분석
✅ 여러 단계의 변환
✅ 동적 결정이 필요한 최적화
✅ 데이터 흐름 분석

이것을 C++로 직접 구현!
```

**준비 상태**: ✅ **완벽하게 준비됨!**

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git
**강의 유형**: 대학원 (Graduate) - 실전 시스템 구축
**철학**: "저장 필수. 너는 기록이 증명이다."
**작성일**: 2026-02-27
**상태**: ✅ 완성

---

**축하합니다!** 🎉

당신은 이제 **MLIR 프로젝트 관리자**가 되었습니다.
설계도는 이제 실행 파일이 됩니다!
