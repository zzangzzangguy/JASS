# JASS - 운동 시설 검색 및 관리 iOS 앱

JASS는 사용자 주변의 운동 시설을 쉽게 찾고 관리할 수 있는 iOS 애플리케이션입니다.

## 주요 기능

- 위치 기반 운동 시설 검색
- 시설 상세 정보 조회
- 즐겨찾기 기능
- 최근 본 시설 기록
- 지도 상에서 시설 위치 확인

## 기술 스택

- Swift
- UIKit
- RxSwift / RxCocoa
- Realm
- GoogleMaps / GooglePlaces API
- SnapKit

## 아키텍처 및 디자인 패턴

- MVVM-C (Model-View-ViewModel + Coordinator)
- Clean Architecture
- Repository Pattern
- Dependency Injection
- Protocol-Oriented Programming

## 주요 구현 사항

1. **RxSwift를 활용한 반응형 프로그래밍**
   - 비동기 작업 관리 및 데이터 흐름 제어
   - Input/Output 패턴을 통한 ViewModel 인터페이스 표준화

2. **Clean Architecture 적용**
   - Use Case, Repository, Entity 계층 구현
   - 비즈니스 로직과 UI 로직의 명확한 분리

3. **Coordinator 패턴**
   - 화면 전환 로직을 ViewController에서 분리
   - 모듈 간 의존성 감소 및 재사용성 향상

4. **Realm을 이용한 로컬 데이터 관리**
   - 즐겨찾기 및 최근 본 시설 정보 저장
   - 오프라인 모드 지원

5. **Google Maps 및 Places API 연동**
   - 실시간 위치 기반 서비스 구현
   - 지도 상에서 시설 위치 시각화

## 성과
 본래 MVVM 으로만 설계되었던 프로젝트를 Rx Swift , Clean Archtiecture , Coordinator 패턴 도입
- 코드 모듈화 및 재사용성 70% 향상
- 앱 크래시 율 감소
- MVVM에서 MVVM-C 및 Clean Architecture로의 성공적인 마이그레이션

<img src="https://github.com/user-attachments/assets/af2c2702-98b0-45d4-9515-55249b6e3d41" width="200" height="400"/>
<img src="https://github.com/user-attachments/assets/b10e4b05-c075-4a48-8693-f978c51f54e9" width="200" height="400"/>
<img src="https://github.com/user-attachments/assets/e65a135f-1090-4310-a389-c0ced3a4cc9f" width="200" height="400"/>
<img src="https://github.com/user-attachments/assets/380b8a90-350f-4cd4-a2c3-45a7784689e0" width="200" height="400"/>
<img src="https://github.com/user-attachments/assets/1f3cbd76-f95c-41f2-abf1-b2180d072e02" width="200" height="400"/>
<img src="https://github.com/user-attachments/assets/fff2a92e-5ddf-44db-980b-609a02e11910" width="200" height="400"/>
<img src="https://github.com/user-attachments/assets/7794be89-b08d-40ee-9c8d-991d756f00b1" width="200" height="400"/>
<img src="https://github.com/user-attachments/assets/6bf5781f-55ca-4c06-8bec-aa111bba5da7" width="200" height="400"/>
<img src="https://github.com/user-attachments/assets/a302a7dc-f0e2-4f75-8733-2b95f35f4f62" width="200" height="400"/>
<img src="https://github.com/user-attachments/assets/9eb12968-2558-4174-a3d4-af8cf8fb7e99" width="200" height="400"/>


