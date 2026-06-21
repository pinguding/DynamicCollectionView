# DynamicCollectionView

`UICollectionView` 의 `UICollectionViewCompositionalLayout` 과 `UICollectionViewDiffableDataSource` 를 **SwiftUI 에서도 최대한 그대로 사용할 수 있도록** 만든 프로젝트입니다.

데이터(Section / Cell / ReusableView 모델)에 따라 동적으로 구성되는 CompositionalLayout 기반 CollectionView 와, 이를 SwiftUI 에서 선언형으로 감싼 래퍼를 **3rd-party 의존성 없이** 제공합니다.

- ✅ **UIKit `UIDynamicCollectionView`** + **SwiftUI `DynamicCollectionView`** 양쪽 지원
- ✅ SwiftUI 진입점은 **값 / 바인딩(`$`) init 모두 제공**
- ✅ **데이터 = 셀** — 모델 하나가 곧 셀 하나로 1:1 매핑
- ✅ **레이아웃 DSL** — Grid / List / WaterFall 을 result builder 로 선언
- ✅ `UICollectionViewDiffableDataSource` 기반 **자동 diff** (추가/삭제/이동 애니메이션)
- ✅ 전체 public API **DocC 문서화**

---

## 목차

- [요구 사항](#요구-사항)
- [설치](#설치-swift-package-manager)
- [구조](#구조)
  - [디렉터리](#디렉터리)
  - [레이어 설계](#레이어-설계)
  - [데이터 흐름](#데이터-흐름)
- [핵심 개념](#핵심-개념)
- [SwiftUI 에서 사용](#swiftui-에서-사용)
  - [셀 정의 (모델 + 뷰)](#셀-정의-모델--뷰)
  - [섹션 정의 & 화면 표시](#섹션-정의--화면-표시)
  - [Grid 레이아웃](#grid-레이아웃)
  - [중첩 그룹 (그룹 안의 그룹)](#중첩-그룹-그룹-안의-그룹)
  - [List 레이아웃](#list-레이아웃)
  - [WaterFall 레이아웃](#waterfall-레이아웃)
  - [Carousel (가로 페이징)](#carousel-가로-페이징)
  - [Header / Footer](#header--footer)
  - [다중 섹션](#다중-섹션)
  - [이벤트 핸들러](#이벤트-핸들러)
  - [페이지네이션 (무한 스크롤)](#페이지네이션-무한-스크롤)
  - [데이터 갱신 (선언형)](#데이터-갱신-선언형)
- [UIKit 에서 사용](#uikit-에서-사용)
  - [셀 / 모델 / 섹션 정의](#셀--모델--섹션-정의)
  - [UIDynamicCollectionView 사용](#uidynamiccollectionview-사용)
  - [증분 갱신 API](#증분-갱신-api)
- [레이아웃 DSL 레퍼런스](#레이아웃-dsl-레퍼런스)
- [라이선스](#라이선스)

---

## 요구 사항

- iOS 14.0+
- Swift 5.9+

## 설치 (Swift Package Manager)

`Package.swift` 의 의존성에 추가:

```swift
dependencies: [
    .package(url: "https://github.com/pinguding/DynamicCollectionView.git", from: "1.0.0")
]
```

또는 Xcode 의 **File ▸ Add Package Dependencies…** 에 저장소 URL 을 입력합니다.

---

## 구조

### 디렉터리

```
Sources/DynamicCollectionView/
├── Internal/
│   └── Array+Safe.swift            # 범위 밖 인덱스 → nil (크래시 방지) 내부 헬퍼
│
├── UIKit/                          # CompositionalLayout 구동 엔진 (UIKit 레이어)
│   ├── UIDynamicCollectionView.swift   # DiffableDataSource 기반 핵심 컬렉션 뷰
│   ├── UISection.swift             # 섹션 추상화 프로토콜 + 내부 Configurator
│   ├── UICell.swift                # 셀이 채택하는 프로토콜
│   ├── UICellConfigurableModel.swift      # 셀 모델 프로토콜 (모델→셀 dequeue/configure)
│   ├── UICellConfigurator.swift           # 추상 셀 모델의 내부 구체화 래퍼
│   ├── UIReusableView.swift               # 서플먼터리(헤더/푸터)가 채택하는 프로토콜
│   ├── UIReusableViewConfigurableModel.swift  # 서플먼터리 모델 프로토콜
│   ├── UIReusableViewConfigurator.swift       # 서플먼터리 모델의 내부 구체화 래퍼
│   └── SelfIdentifiable.swift              # 타입 기반 reuse identifier
│
└── SwiftUI/                        # UIViewRepresentable 래퍼 + 레이아웃 DSL
    ├── DynamicCollectionView.swift        # 선언형 SwiftUI 진입점 (UIViewRepresentable)
    ├── CellView.swift                     # SwiftUI 셀 뷰 프로토콜
    ├── CellViewConfigurableModel.swift    # SwiftUI 셀 모델 프로토콜
    ├── SwiftUICell.swift                  # CellView → UICollectionViewCell 브리지
    ├── ReusableView.swift                 # SwiftUI 서플먼터리 뷰 프로토콜
    ├── ReusableViewConfigurableModel.swift
    ├── SwiftUIReusableView.swift          # ReusableView → UICollectionReusableView 브리지
    └── Section/
        ├── SectionContext.swift           # SwiftUI 섹션 프로토콜 + SwiftUISection 브리지
        ├── LayoutProtocols.swift          # SectionLayout / GroupLayout / ItemLayout / ReusableLayout
        ├── LayoutBuilder.swift            # @resultBuilder (ItemLayoutBuilder / ReusableViewLayoutBuilder)
        ├── LayoutSize.swift               # fractional / estimated / absolute 치수
        ├── ItemLayout/
        │   ├── GridItemLayout.swift       # 단일 아이템
        │   └── ReusableItemLayout.swift   # 헤더/푸터 경계 아이템
        ├── GroupLayout/
        │   ├── HGroupLayout.swift         # 가로 그룹
        │   ├── VGroupLayout.swift         # 세로 그룹
        │   └── WaterFallGroupLayout.swift # Pinterest 식 가변 높이
        └── SectionLayout/
            ├── GridSectionLayout.swift    # 일반 그리드 (헤더/푸터/orthogonal 지원)
            └── ListSectionLayout.swift     # UITableView 형태
```

### 레이어 설계

라이브러리는 **2개 레이어**로 나뉩니다.

```
┌─────────────────────────────────────────────────────────────┐
│  SwiftUI 레이어                                                │
│  DynamicCollectionView (UIViewRepresentable)                  │
│   ├─ SectionContext      ← 사용자가 정의하는 섹션              │
│   ├─ CellView / CellViewConfigurableModel        (셀)         │
│   ├─ ReusableView / ReusableViewConfigurableModel (헤더/푸터)  │
│   └─ 레이아웃 DSL (Grid/List/HGroup/VGroup/WaterFall…)         │
└───────────────────────────┬─────────────────────────────────┘
                            │  SwiftUISection / SwiftUICell 로 브리지
┌───────────────────────────▼─────────────────────────────────┐
│  UIKit 레이어 (엔진)                                          │
│  UIDynamicCollectionView                                     │
│   ├─ UISection                                               │
│   ├─ UICell / UICellConfigurableModel                        │
│   ├─ UIReusableView / UIReusableViewConfigurableModel        │
│   └─ UICollectionViewDiffableDataSource + CompositionalLayout │
└─────────────────────────────────────────────────────────────┘
```

- **UIKit 레이어**가 실제 엔진입니다. `UIDynamicCollectionView` 는 `UICollectionViewDiffableDataSource` 와 `UICollectionViewCompositionalLayout` 을 들고, `UISection` / `UICellConfigurableModel` / `UIReusableViewConfigurableModel` 세 가지 추상 모델로 화면을 구성합니다. UIKit 만으로도 단독 사용할 수 있습니다.
- **SwiftUI 레이어**는 그 위를 감싼 래퍼입니다. `DynamicCollectionView` 는 `UIViewRepresentable` 로 `UIDynamicCollectionView` 를 호스팅하고, 사용자가 정의한 `SectionContext` 를 내부적으로 `SwiftUISection` 으로 변환해 엔진에 전달합니다. SwiftUI 셀/서플먼터리 뷰는 `SwiftUICell` / `SwiftUIReusableView` 가 `UIHostingController` 로 감싸 올립니다.

### 데이터 흐름

```
[사용자 데이터]
   │  ColorItem(:CellViewConfigurableModel), GridSection(:SectionContext) …
   ▼
DynamicCollectionView(sections)         // SwiftUI 진입점
   │  sections.map { SwiftUISection($0) }
   ▼
UIDynamicCollectionView.apply(sections:) // DiffableDataSource 스냅샷 적용
   │  section.id / item.id 로 diff → 추가·삭제·이동 애니메이션
   ▼
cellProvider → UICellConfigurator       // 모델 타입으로 셀 타입/식별자 해석 + 자동 register
   │
   ▼
SwiftUICell<CellView>                    // UIHostingController 로 CellView 호스팅 → 화면
```

핵심은 **모델이 곧 셀**이라는 점입니다. `CellViewConfigurableModel` 의 연관타입(`CellViewType`)이 어떤 SwiftUI 뷰로 그려질지를 결정하므로, 같은 섹션 안에 서로 다른 타입의 셀을 섞어도 각 모델이 자기 셀을 알아서 dequeue 합니다. 셀/서플먼터리의 `register` 도 `apply`/`append` 시 자동 처리되어 별도 등록 코드가 필요 없습니다.

---

## 핵심 개념

| 프로토콜 | 역할 |
|---|---|
| `SectionContext` | 하나의 섹션 = `id` + `items`(셀 모델) + `reusableItems`(헤더/푸터 모델) + `layout`(레이아웃) |
| `CellViewConfigurableModel` | 셀 데이터 모델. 연관타입 `CellViewType` 으로 매핑될 SwiftUI 셀을 지정. **`ObservableObject` 채택 불필요** (관찰이 필요할 때만 직접 채택) |
| `CellView` | 셀로 그려질 SwiftUI `View`. `init(model:indexPath:)` 요구 |
| `ReusableViewConfigurableModel` / `ReusableView` | 헤더·푸터(서플먼터리) 모델/뷰. `static var elementKind` 로 헤더/푸터 구분 |
| `SectionLayout` | 섹션의 레이아웃. `GridSectionLayout`, `ListSectionLayout` 제공 |

> 아래 모든 예시는 함께 제공되는 데모 앱에서 **빌드·동작이 검증된 코드**입니다.

---

## SwiftUI 에서 사용

선언형 `DynamicCollectionView` 에 `[any SectionContext]` 배열을 넘기는 방식입니다.

### 셀 정의 (모델 + 뷰)

`CellViewConfigurableModel`(데이터)과 `CellView`(SwiftUI 뷰)를 1:1 로 정의합니다. **`ObservableObject` 가 필요 없으므로** 단순 모델은 평범한 `final class` 로 둡니다.

```swift
import SwiftUI
import DynamicCollectionView

// 데이터 모델 — 관찰이 필요 없으면 그냥 final class
final class ColorItem: CellViewConfigurableModel {
    typealias CellViewType = ColorCell      // 이 모델이 그려질 셀

    let id: String                          // DiffableDataSource 식별자
    let title: String
    let color: Color

    init(id: String, title: String, color: Color) {
        self.id = id
        self.title = title
        self.color = color
    }
}

// 1:1 매칭되는 SwiftUI 셀
struct ColorCell: CellView {
    private let model: ColorItem

    init(model: ColorItem, indexPath: IndexPath) {
        self.model = model
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(model.color)
            .overlay(Text(model.title).font(.headline).foregroundColor(.white))
    }
}
```

### 섹션 정의 & 화면 표시

`SectionContext` 로 섹션을 정의하고, `DynamicCollectionView` 에 섹션 배열을 넘기면 끝입니다. 섹션은 **값 타입(struct)** 으로 두는 것을 권장합니다(복사 후 수정이 안전).

```swift
struct ColorSection: SectionContext {
    let id: String
    var items: [any CellViewConfigurableModel]
    var reusableItems: [String: [any ReusableViewConfigurableModel]] = [:]

    init(id: String, items: [ColorItem]) {
        self.id = id
        self.items = items
    }

    // 전체 너비 64pt 행 그리드
    var layout: some SectionLayout {
        GridSectionLayout(body: { _, _ in
            HGroupLayout(width: .fractionalWidth(1.0), height: .absolute(64)) {
                GridItemLayout(width: .fractionalWidth(1.0), height: .fractionalHeight(1.0))
            }
        })
        .interGroupSpacing(8)
    }
}

struct ContentView: View {
    @State private var sections: [any SectionContext] = [
        ColorSection(id: "main", items: [
            ColorItem(id: "1", title: "Red",  color: .red),
            ColorItem(id: "2", title: "Blue", color: .blue),
        ])
    ]

    var body: some View {
        DynamicCollectionView(sections)
    }
}
```

`init` 은 **값**과 **바인딩** 두 가지를 제공합니다. `@State` 등을 `$` 로 넘기고 싶을 때 바인딩 init 을 쓰며, 동작은 값 기반과 동일합니다(매 업데이트마다 현재 값을 읽어 적용).

```swift
@State private var sections: [any SectionContext] = ...

DynamicCollectionView(sections)    // 값
DynamicCollectionView($sections)   // 바인딩
```

### Grid 레이아웃

`HGroupLayout` 안에 너비 1/N 짜리 `GridItemLayout` 을 N 개 두면 N 열 그리드가 됩니다.

```swift
var layout: some SectionLayout {
    GridSectionLayout(body: { _, _ in
        HGroupLayout(width: .fractionalWidth(1.0), height: .absolute(110)) {
            GridItemLayout(width: .fractionalWidth(1.0 / 3.0), height: .fractionalHeight(1.0))
            GridItemLayout(width: .fractionalWidth(1.0 / 3.0), height: .fractionalHeight(1.0))
            GridItemLayout(width: .fractionalWidth(1.0 / 3.0), height: .fractionalHeight(1.0))
        }
    })
}
```

### 중첩 그룹 (그룹 안의 그룹)

`GroupLayout` 은 `ItemLayout` 을 채택하므로, 그룹의 subitem 으로 **또 다른 그룹**을 넣어 복잡한 CompositionalLayout 을 표현할 수 있습니다. 아래는 **가로 그룹 = [큰 아이템 1개(2/3)] + [세로 그룹(1/3): 작은 아이템 2개]** 형태의 매거진 레이아웃입니다.

```swift
var layout: some SectionLayout {
    GridSectionLayout(body: { _, _ in
        // 가로 그룹: 왼쪽 큰 아이템 + 오른쪽 세로 그룹
        HGroupLayout(width: .fractionalWidth(1.0), height: .absolute(200)) {
            GridItemLayout(width: .fractionalWidth(2.0 / 3.0), height: .fractionalHeight(1.0))

            // 그룹 안의 그룹: 작은 아이템 2개를 세로로 스택
            VGroupLayout(width: .fractionalWidth(1.0 / 3.0), height: .fractionalHeight(1.0)) {
                GridItemLayout(width: .fractionalWidth(1.0), height: .fractionalHeight(0.5))
                GridItemLayout(width: .fractionalWidth(1.0), height: .fractionalHeight(0.5))
            }
        }
    })
    .interGroupSpacing(6)
}
```

이 그룹(아이템 3개)이 데이터 길이만큼 세로로 반복됩니다. 결과는 다음과 같습니다(큰 아이템 1 + 작은 아이템 2가 한 줄):

```
┌─────────────────┬───────┐
│                 │  작은  │
│     큰 아이템     ├───────┤
│                 │  작은  │
└─────────────────┴───────┘
```

> `HGroupLayout` / `VGroupLayout` 을 임의 깊이로 중첩할 수 있습니다. `WaterFallGroupLayout` 을 제외한 그룹은 모두 `ItemLayout` 이므로 어디든 subitem 으로 넣을 수 있습니다.

### List 레이아웃

`ListSectionLayout` 은 `UICollectionLayoutListConfiguration` 기반으로 셀프사이징 행을 그립니다.

```swift
var layout: some SectionLayout {
    ListSectionLayout(.plain)   // .plain / .grouped / .insetGrouped …
}
```

### WaterFall 레이아웃

`WaterFallGroupLayout` 으로 Pinterest 식 가변 높이 레이아웃을 구성합니다. 각 아이템의 높이를 `itemHeightContext` 로 알려줍니다.

```swift
struct WaterfallSection: SectionContext {
    let id: String
    var items: [any CellViewConfigurableModel]
    var reusableItems: [String: [any ReusableViewConfigurableModel]] = [:]

    private let heights: [CGFloat]

    init(id: String, photos: [PhotoItem]) {
        self.id = id
        self.items = photos
        self.heights = photos.map(\.height)
    }

    var layout: some SectionLayout {
        let heights = self.heights
        return GridSectionLayout(body: { _, environment in
            WaterFallGroupLayout(
                numberOfColumn: 2,
                numberOfItems: heights.count,
                environment: environment,
                itemHeightContext: { index, _ in heights[index] }
            )
            .interItemSpacing(8)
        })
        .interGroupSpacing(8)
    }
}
```

### Carousel (가로 페이징)

`GridSectionLayout.orthogonalScrollingBehavior(_:)` 로 가로 스크롤 캐러셀을 만듭니다. 그룹 너비를 1.0 미만으로 두면 옆 카드가 살짝 보입니다.

```swift
var layout: some SectionLayout {
    GridSectionLayout(body: { _, _ in
        HGroupLayout(width: .fractionalWidth(0.8), height: .absolute(160)) {
            GridItemLayout(width: .fractionalWidth(1.0), height: .fractionalHeight(1.0))
        }
    })
    .orthogonalScrollingBehavior(.groupPagingCentered)
    .interGroupSpacing(12)
}
```

### Header / Footer

서플먼터리 뷰도 셀과 동일한 패턴입니다. `ReusableViewConfigurableModel` + `ReusableView` 를 정의하고, `static var elementKind` 로 헤더/푸터를 구분합니다.

```swift
// 헤더 모델 + 뷰
final class SectionHeaderModel: ReusableViewConfigurableModel {
    typealias ReusableViewType = SectionHeaderView
    let id: String
    let title: String
    init(id: String, title: String) { self.id = id; self.title = title }
}

struct SectionHeaderView: ReusableView {
    static var elementKind: ReusableViewElementKind { .header }   // .footer 도 가능
    private let model: SectionHeaderModel
    init(model: SectionHeaderModel, indexPath: IndexPath) { self.model = model }
    var body: some View {
        HStack { Text(model.title).font(.headline); Spacer() }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.15))
    }
}

// 섹션에서 reusableItems + 레이아웃의 header/footer 클로저로 연결
struct HeaderSection: SectionContext {
    let id: String
    var items: [any CellViewConfigurableModel]
    var reusableItems: [String: [any ReusableViewConfigurableModel]]

    init(id: String, items: [ColorItem], headerTitle: String) {
        self.id = id
        self.items = items
        self.reusableItems = [
            ReusableViewElementKind.header.rawValue: [SectionHeaderModel(id: "\(id)-h", title: headerTitle)]
        ]
    }

    var layout: some SectionLayout {
        GridSectionLayout(
            header: { _, _ in ReusableItemLayout(kind: .header, height: .absolute(44)) },
            body: { _, _ in
                HGroupLayout(width: .fractionalWidth(1.0), height: .absolute(60)) {
                    GridItemLayout(width: .fractionalWidth(1.0), height: .fractionalHeight(1.0))
                }
            }
        )
    }
}
```

### 다중 섹션

`DynamicCollectionView` 에 서로 다른 레이아웃의 섹션을 섞어 넘기면, 섹션마다 자기 레이아웃으로 그려집니다.

```swift
let sections: [any SectionContext] = [
    CarouselSection(id: "banner",  items: banners),     // 가로 캐러셀
    GridSection(id: "grid",        items: products),    // 3열 그리드
    ListSection(id: "list",        items: rows)         // 리스트
]

DynamicCollectionView(sections)
```

### 이벤트 핸들러

체이닝 모디파이어로 선택·표시 이벤트를 받습니다. 핸들러는 매 업데이트마다 갱신되어 **항상 최신 상태**로 호출됩니다.

```swift
DynamicCollectionView(sections)
    .didSelectItem { item, indexPath in
        guard let item = item as? ColorItem else { return }
        print("선택: \(item.title) @ \(indexPath)")
    }
    .willDisplayItem { item, indexPath in
        // 셀이 화면에 나타나기 직전 (노출 로깅, 페이지네이션 등)
    }
    .willDisplayReusableItem { item, indexPath in
        // 헤더/푸터가 나타나기 직전
    }
    .keyboardDismissMode(.onDrag)   // 스크롤 시 키보드 내림
```

### 페이지네이션 (무한 스크롤)

`willDisplayItem` 에서 마지막 근처 아이템 표시를 감지해 다음 페이지를 로드합니다. 선언형이므로 **새 데이터를 합쳐 sections 를 다시 만들면** diff 가 추가분만 애니메이션합니다.

```swift
struct FeedView: View {
    @State private var items: [ColorItem] = []

    private var sections: [any SectionContext] {
        [GridSection(id: "feed", items: items)]
    }

    var body: some View {
        DynamicCollectionView(sections)
            .willDisplayItem { _, indexPath in
                if indexPath.item >= items.count - 3 {   // 끝에서 3번째 도달
                    loadNextPage()
                }
            }
            .onAppear { loadNextPage() }
    }

    private func loadNextPage() {
        // 비동기 로드 후 메인에서 합치기
        items.append(contentsOf: nextPageItems())
    }
}
```

### 데이터 갱신 (선언형)

데이터 갱신은 별도 API 없이 **sections(또는 그 source 가 되는 state)를 바꾸기만** 하면 됩니다. `id` 기반 diff 로 추가/삭제/이동이 자동 애니메이션됩니다.

```swift
struct EditableView: View {
    // 진짜 상태는 items(셀 데이터). sections 는 거기서 파생한다.
    @State private var items: [ColorItem] = ColorItem.sample()

    private var sections: [any SectionContext] {
        [ColorSection(id: "main", items: items)]
    }

    var body: some View {
        VStack {
            HStack {
                Button("추가")  { items.append(ColorItem.random()) }   // 삽입 애니메이션
                Button("섞기")  { items.shuffle() }                   // 이동 애니메이션
                Button("비우기") { items.removeAll() }                 // 삭제 애니메이션
            }
            DynamicCollectionView(sections)
        }
    }
}
```

---

## UIKit 에서 사용

SwiftUI 없이 엔진(`UIDynamicCollectionView`)을 ViewController 에서 직접 쓸 수 있습니다. 이때는 SwiftUI 측 프로토콜 대신 **`UICell` / `UICellConfigurableModel` / `UISection`** 을 구현합니다. 레이아웃은 `UISection.sectionLayout(...)` 에서 `NSCollectionLayoutSection` 을 직접 반환합니다.

### 셀 / 모델 / 섹션 정의

```swift
import UIKit
import DynamicCollectionView

// 1) 셀 — UICollectionViewCell + UICell
final class ColorCell: UICollectionViewCell, UICell {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(model: ColorModel, at indexPath: IndexPath) {
        contentView.backgroundColor = model.color
        label.text = model.title
    }
}

// 2) 셀 모델 — UICellConfigurableModel (CellType 으로 위 셀과 매핑)
final class ColorModel: UICellConfigurableModel {
    typealias CellType = ColorCell

    let id: String
    let title: String
    let color: UIColor

    init(id: String, title: String, color: UIColor) {
        self.id = id
        self.title = title
        self.color = color
    }
}

// 3) 섹션 — UISection (레이아웃은 NSCollectionLayoutSection 직접 반환)
final class ColorSection: UISection {
    let id: String
    var items: [any UICellConfigurableModel]
    var reusableItems: [String: [any UIReusableViewConfigurableModel]] = [:]

    init(id: String, items: [ColorModel]) {
        self.id = id
        self.items = items
    }

    func sectionLayout(_ collectionView: UICollectionView?, sectionIndex: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(1.0 / 3.0),
            heightDimension: .fractionalHeight(1.0)
        ))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(110)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        return section
    }
}
```

### UIDynamicCollectionView 사용

```swift
final class FeedViewController: UIViewController {
    private let collectionView = UIDynamicCollectionView()

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let models = (0..<18).map { ColorModel(id: "\($0)", title: "#\($0)", color: .systemBlue) }
        collectionView.apply(sections: [ColorSection(id: "main", items: models)], animated: false)
    }
}
```

> 셀 컴포넌트의 `register` 는 `apply`/`append` 시 내부에서 자동 처리되므로 별도 등록 코드가 필요 없습니다.

### 증분 갱신 API

```swift
// 전체 적용 (DiffableDataSource 스냅샷)
collectionView.apply(sections: sections, animated: true)

// 섹션 / 아이템 증분 추가 (페이지네이션)
collectionView.append(sections: moreSections, animated: true)
collectionView.append(items: moreItems, at: "main", animated: true)

// 특정 섹션 reload
collectionView.reloadSection(["main"])
```

---

## 레이아웃 DSL 레퍼런스

> 레이아웃 DSL 은 SwiftUI 측 `SectionContext.layout` 에서 사용합니다. (UIKit `UISection` 은 `NSCollectionLayoutSection` 을 직접 반환)

| 타입 | 종류 | 설명 |
|---|---|---|
| `GridSectionLayout` | SectionLayout | 일반 그리드. `header` / `body` / `footer` 클로저, `interGroupSpacing`, `contentInsets`, `orthogonalScrollingBehavior`, `visibleItem` 지원 |
| `ListSectionLayout` | SectionLayout | `UICollectionLayoutListConfiguration` 기반 리스트. `contentInset` 지원 |
| `HGroupLayout` / `VGroupLayout` | GroupLayout | 가로 / 세로 그룹. `@ItemLayoutBuilder` 로 하위 아이템 구성 (그룹 중첩 가능) |
| `WaterFallGroupLayout` | GroupLayout | Pinterest 식 가변 높이 (`NSCollectionLayoutGroup.custom`) |
| `GridItemLayout` | ItemLayout | 단일 아이템 (width × height) |
| `ReusableItemLayout` | ReusableLayout | 헤더/푸터 경계 아이템 (`kind` + height) |

### `LayoutSize`

```swift
.fractionalWidth(0.5)    // 컨테이너 너비의 50%
.fractionalHeight(1.0)   // 컨테이너 높이의 100%
.estimated(120)          // 추정값 (콘텐츠에 따라 자동 조정)
.absolute(64)            // 64pt 고정
```

### `OrthogonalScrollingBehavior`

`.none` · `.continuous` · `.continuousGroupLeadingBoundary` · `.paging` · `.groupPaging` · `.groupPagingCentered`

---

## 라이선스

[MIT](LICENSE)
