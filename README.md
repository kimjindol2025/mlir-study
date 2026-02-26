# 🔧 MLIR 학습 프로젝트

> Multi-Level Intermediate Representation (MLIR) 컴파일러 설계 학습

---

## 🎯 **프로젝트 개요**

MLIR은 LLVM 프로젝트의 일부로, 여러 수준의 중간 표현(IR)을 지원하는 컴파일러 인프라입니다.
이 프로젝트는 MLIR의 기초부터 고급 기법까지 단계별로 배웁니다.

### **목표**
- ✅ MLIR 아키텍처 이해 (Dialects, Operations, Type System)
- ✅ MLIR C++ API 활용
- ✅ 간단한 언어 → MLIR 변환
- ✅ MLIR 최적화 Pass 구현
- ✅ MLIR → LLVM IR 변환
- ✅ 실제 컴파일러 구축

---

## 📁 **프로젝트 구조**

```
mlir-study/
├── README.md              (이 파일)
├── .gitignore             (Git 무시 설정)
├── CMakeLists.txt         (빌드 설정)
├── go.mod                 (Go 모듈 설정)
│
├── lessons/               (학습 자료)
│   ├── 1_mlir_basics.md
│   ├── 2_dialects.md
│   ├── 3_operations.md
│   ├── 4_type_system.md
│   └── ...
│
├── exercises/             (실습 문제)
│   ├── 01_hello_mlir/
│   ├── 02_custom_dialect/
│   └── ...
│
├── projects/              (프로젝트)
│   ├── simple_lang/       (간단한 언어 구현)
│   ├── optimizer/         (최적화 Pass)
│   └── compiler/          (전체 컴파일러)
│
├── research/              (연구 노트)
│   ├── papers.md
│   ├── optimization_techniques.md
│   └── ...
│
├── notes/                 (개인 노트)
│   └── learning_path.md
│
├── benchmarks/            (성능 테스트)
│   ├── compile_time.cpp
│   └── runtime_perf.cpp
│
└── docs/                  (문서)
    ├── ARCHITECTURE.md
    ├── API_REFERENCE.md
    └── SETUP.md
```

---

## 🚀 **학습 로드맵**

### **Phase 1: 기초 (1-2주)**
```
✅ MLIR이란? (개념, 역사, 왜 필요한가?)
✅ MLIR 아키텍처 (Dialects, Operations, SSA)
✅ MLIR 설치 및 빌드
✅ 첫 MLIR 프로그램 (Hello MLIR)
✅ 기본 Dialect (std, linalg, affine)
```

### **Phase 2: 핵심 개념 (2-3주)**
```
🔜 Type System (Integer, Float, Tensor, Vector)
🔜 Operations & Attributes
🔜 Region & Block
🔜 SSA와 Control Flow
🔜 Pass Framework
```

### **Phase 3: 실습 (2-3주)**
```
🔜 Custom Dialect 정의
🔜 간단한 언어 → MLIR 변환
🔜 최적화 Pass 구현
🔜 MLIR → LLVM IR 변환
```

### **Phase 4: 고급 (3-4주)**
```
🔜 Affine Dialect (루프 최적화)
🔜 Vector Dialect (SIMD)
🔜 GPU 코드 생성 (GPU Dialect)
🔜 벡터화 및 병렬화
```

### **Phase 5: 프로젝트 (4-5주)**
```
🔜 완전한 컴파일러 구축
🔜 성능 최적화
🔜 벤치마킹
```

---

## 📊 **현재 상태**

| 항목 | 상태 |
|------|------|
| 폴더 구조 | ✅ 준비 완료 |
| Git 저장소 | ✅ 초기화 완료 |
| 환경 설정 | 🔜 진행예정 |
| 첫 강의 | 🔜 예정 |
| 첫 실습 | 🔜 예정 |

---

## 🛠️ **필수 요구사항**

- **LLVM/MLIR**: 13.0.0+
- **C++ Compiler**: GCC 9+ or Clang 11+
- **CMake**: 3.16+
- **Go**: 1.16+ (문서 및 도구용)
- **Python**: 3.8+ (스크립트용)

---

## 📖 **참고 자료**

- [MLIR 공식 문서](https://mlir.llvm.org/)
- [MLIR Toy Tutorial](https://mlir.llvm.org/docs/Tutorials/Toy/)
- [LLVM Developer Meeting 발표](https://www.youtube.com/c/LLVM)

---

## 🎓 **학습 전략**

1. **이론 먼저**: 각 주제의 개념을 깊이 있게 학습
2. **코드 읽기**: LLVM/MLIR 소스 코드 분석
3. **실습 문제**: 단계별 실습 과제 해결
4. **프로젝트**: 실제 컴파일러 구축

---

## 📝 **진행 기록**

### **2026-02-27 시작**
- ✅ 프로젝트 폴더 생성
- ✅ 디렉토리 구조 설계
- ✅ Git 저장소 초기화
- 🔜 첫 강의 작성 시작

---

**저장소**: https://gogs.dclub.kr/kim/mlir-study.git (예정)
**작성자**: Claude (Haiku 4.5)
**시작일**: 2026-02-27
