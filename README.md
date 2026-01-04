# 📏 Tape Measure - AR 줄자 앱

ARKit(iOS)과 ARCore(Android)를 활용한 **증강현실 기반 거리 측정 앱**입니다.

카메라로 실제 공간을 인식하고, 화면을 탭하여 두 점 사이의 실제 거리를 측정할 수 있습니다.

## 스크린샷

| 평면 감지 | 거리 측정 |
|:---:|:---:|
| 🔍 바닥/테이블 등 평면 자동 인식 | 📐 두 점 사이 실제 거리 표시 |

## 주요 기능

- **평면 감지**: 바닥, 테이블, 벽 등 수평/수직 평면 자동 인식
- **탭으로 측정**: 화면 탭으로 시작점과 끝점 지정
- **실시간 거리 표시**: cm, mm, inch 단위 동시 표시
- **AR 시각화**: 측정점과 측정선이 실제 공간에 오버레이
- **크로스 플랫폼**: iOS(ARKit)와 Android(ARCore) 모두 지원

## 기술 스택

| 분류 | 기술 |
|------|------|
| **Framework** | Flutter 3.x |
| **iOS AR** | ARKit (arkit_plugin) |
| **Android AR** | ARCore (arcore_flutter_plugin) |
| **수학 연산** | vector_math |

## 요구 사항

### iOS
- iOS 12.0 이상
- ARKit 지원 기기 (iPhone 6s 이상)

### Android
- Android 7.0 (API 24) 이상
- ARCore 지원 기기 ([지원 기기 목록](https://developers.google.com/ar/devices))

## 설치 및 실행

### 1. 프로젝트 클론

```bash
git clone https://github.com/seunggulee1007/tape-measure.git
cd tape-measure
```

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. iOS 설정 (macOS만 해당)

```bash
cd ios
pod install
cd ..
```

### 4. 앱 실행

```bash
# 연결된 기기 확인
flutter devices

# 앱 실행 (실제 기기 필요)
flutter run
```

> ⚠️ **주의**: AR 기능은 시뮬레이터/에뮬레이터에서 테스트할 수 없습니다. 실제 기기가 필요합니다.

## 사용 방법

1. **앱 실행** → 카메라 권한 허용
2. **평면 스캔** → 핸드폰을 천천히 움직여 평면 감지
3. **첫 번째 점 탭** → 측정 시작점 지정 (녹색 점)
4. **두 번째 점 탭** → 측정 끝점 지정 (빨간 점)
5. **결과 확인** → 두 점 사이 거리가 화면에 표시

## 프로젝트 구조

```
lib/
├── main.dart                     # 앱 진입점
├── screens/
│   ├── ruler_screen.dart         # 플랫폼별 분기
│   ├── ar_ruler_ios.dart         # iOS ARKit 화면
│   └── ar_ruler_android.dart     # Android ARCore 화면
└── utils/
    └── measurement_utils.dart    # 거리 계산 유틸리티
```

## AR 거리 측정 원리

AR은 단순한 카메라 영상이 아닌 **3D 공간을 인식**합니다.

```
1. 카메라로 환경 스캔 → 특징점(Feature Points) 추출
2. 평면 감지 → 바닥, 벽 등 평면의 3D 좌표 계산
3. 탭 위치 → Hit Test로 탭한 위치의 실제 3D 좌표 획득
4. 거리 계산 → 두 3D 점 사이 유클리드 거리
```

### 거리 계산 공식

```dart
distance = √[(x₂-x₁)² + (y₂-y₁)² + (z₂-z₁)²]
```

## 테스트

```bash
flutter test
```

## 라이선스

MIT License

## 기여

이슈와 PR은 언제나 환영합니다!
