# DynamicCollectionView

English · **[한국어](README_Kor.md)**

> **A render engine for Server-Driven UI.**
> A `UICollectionView`-based dynamic rendering engine where the screen's layout and composition are determined purely by data (Section / Cell / ReusableView models) delivered from the server.

Brings `UICollectionView`'s `UICollectionViewCompositionalLayout` and `UICollectionViewDiffableDataSource` to **SwiftUI as faithfully as possible**, with **no 3rd-party dependencies**.

## Why this library

- 🧩 **Server-Driven UI render engine** — The screen is defined by **data**, not code. When the server delivers the section / cell / layout composition, it is rendered according to the model→cell mapping rules, so **you can change the screen composition without shipping an app update.**
- 🔀 **Heterogeneous cells** — "one model = one cell". Freely mix cells and layouts of different types within a single collection.
- 🎛 **Expressive layout DSL** — Compose Grid · List · WaterFall · carousel · nested groups declaratively, exposing the full power of CompositionalLayout.
- ✨ **Automatic diffing** — DiffableDataSource animates insertions / deletions / moves automatically, keyed by `id`.
- 🧱 **Both UIKit & SwiftUI** — UIKit `UIDynamicCollectionView` / SwiftUI `DynamicCollectionView` (both value and binding init). Zero dependencies, entire public API documented with **DocC**.

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation-swift-package-manager)
- [Architecture](#architecture)
  - [Directory layout](#directory-layout)
  - [Layer design](#layer-design)
  - [Data flow](#data-flow)
- [Core concepts](#core-concepts)
- [Using in SwiftUI](#using-in-swiftui)
  - [Defining a cell (model + view)](#defining-a-cell-model--view)
  - [Cell state: keep the model as the single source of truth](#cell-state-keep-the-model-as-the-single-source-of-truth)
  - [Defining a section & displaying it](#defining-a-section--displaying-it)
  - [Grid layout](#grid-layout)
  - [Nested groups (group within a group)](#nested-groups-group-within-a-group)
  - [List layout](#list-layout)
  - [WaterFall layout](#waterfall-layout)
  - [Carousel (horizontal paging)](#carousel-horizontal-paging)
  - [Header / Footer](#header--footer)
  - [Multiple sections](#multiple-sections)
  - [Event handlers](#event-handlers)
  - [Pagination (infinite scroll)](#pagination-infinite-scroll)
  - [Updating data (declarative)](#updating-data-declarative)
- [Using in UIKit](#using-in-uikit)
  - [Defining cell / model / section](#defining-cell--model--section)
  - [Using UIDynamicCollectionView](#using-uidynamiccollectionview)
  - [Incremental update API](#incremental-update-api)
- [Layout DSL reference](#layout-dsl-reference)
- [License](#license)

---

## Requirements

- iOS 14.0+
- Swift 5.9+

## Installation (Swift Package Manager)

Add it to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/pinguding/DynamicCollectionView.git", from: "1.3.0")
]
```

Or use Xcode's **File ▸ Add Package Dependencies…** and enter the repository URL.

---

## Architecture

### Directory layout

```
Sources/DynamicCollectionView/
├── Internal/
│   └── Array+Safe.swift            # internal helper: out-of-range index → nil (crash-safe)
│
├── UIKit/                          # CompositionalLayout engine (UIKit layer)
│   ├── UIDynamicCollectionView.swift   # core collection view (DiffableDataSource-based)
│   ├── UISection.swift             # section abstraction protocol + internal Configurator
│   ├── UICell.swift                # protocol adopted by cells
│   ├── UICellConfigurableModel.swift      # cell model protocol (model→cell dequeue/configure)
│   ├── UICellConfigurator.swift           # internal concretizing wrapper for abstract cell models
│   ├── UIReusableView.swift               # protocol adopted by supplementary (header/footer) views
│   ├── UIReusableViewConfigurableModel.swift  # supplementary model protocol
│   ├── UIReusableViewConfigurator.swift       # internal concretizing wrapper for supplementary models
│   └── SelfIdentifiable.swift              # type-based reuse identifier
│
└── SwiftUI/                        # UIViewRepresentable wrapper + layout DSL
    ├── DynamicCollectionView.swift        # declarative SwiftUI entry point (UIViewRepresentable)
    ├── CellView.swift                     # SwiftUI cell view protocol
    ├── CellViewConfigurableModel.swift    # SwiftUI cell model protocol
    ├── SwiftUICell.swift                  # CellView → UICollectionViewCell bridge
    ├── ReusableView.swift                 # SwiftUI supplementary view protocol
    ├── ReusableViewConfigurableModel.swift
    ├── SwiftUIReusableView.swift          # ReusableView → UICollectionReusableView bridge
    └── Section/
        ├── SectionContext.swift           # SwiftUI section protocol + SwiftUISection bridge
        ├── LayoutProtocols.swift          # SectionLayout / GroupLayout / ItemLayout / ReusableLayout
        ├── LayoutBuilder.swift            # @resultBuilder (ItemLayoutBuilder / ReusableViewLayoutBuilder)
        ├── LayoutSize.swift               # fractional / estimated / absolute dimensions
        ├── ItemLayout/
        │   ├── GridItemLayout.swift       # single item
        │   └── ReusableItemLayout.swift   # header/footer boundary item
        ├── GroupLayout/
        │   ├── HGroupLayout.swift         # horizontal group
        │   ├── VGroupLayout.swift         # vertical group
        │   └── WaterFallGroupLayout.swift # Pinterest-style variable height
        └── SectionLayout/
            ├── GridSectionLayout.swift    # general grid (header/footer/orthogonal)
            └── ListSectionLayout.swift     # UITableView-style
```

### Layer design

The library is split into **two layers**.

```
┌─────────────────────────────────────────────────────────────┐
│  SwiftUI layer                                                │
│  DynamicCollectionView (UIViewRepresentable)                  │
│   ├─ SectionContext      ← user-defined section               │
│   ├─ CellView / CellViewConfigurableModel        (cell)       │
│   ├─ ReusableView / ReusableViewConfigurableModel (hdr/footer)│
│   └─ Layout DSL (Grid/List/HGroup/VGroup/WaterFall…)          │
└───────────────────────────┬─────────────────────────────────┘
                            │  bridged via SwiftUISection / SwiftUICell
┌───────────────────────────▼─────────────────────────────────┐
│  UIKit layer (engine)                                        │
│  UIDynamicCollectionView                                     │
│   ├─ UISection                                               │
│   ├─ UICell / UICellConfigurableModel                        │
│   ├─ UIReusableView / UIReusableViewConfigurableModel        │
│   └─ UICollectionViewDiffableDataSource + CompositionalLayout │
└─────────────────────────────────────────────────────────────┘
```

- The **UIKit layer** is the actual engine. `UIDynamicCollectionView` holds a `UICollectionViewDiffableDataSource` and a `UICollectionViewCompositionalLayout`, and builds the screen from three abstract models — `UISection` / `UICellConfigurableModel` / `UIReusableViewConfigurableModel`. It can be used standalone with UIKit only.
- The **SwiftUI layer** wraps it. `DynamicCollectionView` hosts `UIDynamicCollectionView` via `UIViewRepresentable`, converting your `SectionContext` into `SwiftUISection` internally before handing it to the engine. SwiftUI cells / supplementary views are hosted by `SwiftUICell` / `SwiftUIReusableView` using `UIHostingController`.

### Data flow

```
[user data]
   │  ColorItem(:CellViewConfigurableModel), GridSection(:SectionContext) …
   ▼
DynamicCollectionView(sections)         // SwiftUI entry point
   │  sections.map { SwiftUISection($0) }
   ▼
UIDynamicCollectionView.apply(sections:) // applies a DiffableDataSource snapshot
   │  diff by section.id / item.id → insert/delete/move animations
   ▼
cellProvider → UICellConfigurator       // resolves cell type/identifier from model + auto-register
   │
   ▼
SwiftUICell<CellView>                    // hosts CellView via UIHostingController → screen
```

The key idea is that **a model is a cell**. The associated type (`CellViewType`) of `CellViewConfigurableModel` decides which SwiftUI view it renders as, so even when you mix different cell types in one section, each model dequeues its own cell. Registration (`register`) of cells/supplementary views is also handled automatically on `apply`/`append`, so no manual registration code is needed.

---

## Core concepts

| Protocol | Role |
|---|---|
| `SectionContext` | One section = `id` + `items` (cell models) + `reusableItems` (header/footer models) + `layout` |
| `CellViewConfigurableModel` | Cell data model. Specifies the mapped SwiftUI cell via `CellViewType`. **No `ObservableObject` required** (adopt it only when you need observation) |
| `CellView` | A SwiftUI `View` rendered as a cell. Requires `init(model:indexPath:)` |
| `ReusableViewConfigurableModel` / `ReusableView` | Header/footer (supplementary) model/view. `static var elementKind` distinguishes header vs footer |
| `SectionLayout` | A section's layout. `GridSectionLayout`, `ListSectionLayout` provided |

> All examples below are **code verified to build & run** in the bundled demo app.

---

## Using in SwiftUI

Pass a `[any SectionContext]` array to the declarative `DynamicCollectionView`.

### Defining a cell (model + view)

Define `CellViewConfigurableModel` (data) and `CellView` (SwiftUI view) 1:1. **Since `ObservableObject` is not required**, simple models can be plain `final class`es.

```swift
import SwiftUI
import DynamicCollectionView

// Data model — just a final class when you don't need observation
final class ColorItem: CellViewConfigurableModel {
    typealias CellViewType = ColorCell      // the cell this model renders as

    let id: String                          // DiffableDataSource identifier
    let title: String
    let color: Color

    init(id: String, title: String, color: Color) {
        self.id = id
        self.title = title
        self.color = color
    }
}

// The matching SwiftUI cell (1:1)
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

### Cell state: keep the model as the single source of truth

A `CellView` is hosted inside a **reused** `UICollectionViewCell`, and its SwiftUI host is recreated every time the cell is reused. This has one firm consequence:

> **Do not store mutable UI state inside a cell with `@State` or `@Binding`.**

Such state does not behave the way you expect under cell reuse:

- It is **reset** whenever the cell is reused (scroll a cell off-screen and back → your toggle is gone).
- If the host were instead kept alive to avoid that reset, the state would **bleed** into unrelated items (item A's "liked" flag shows up on item B that happens to reuse the same cell).

Neither is tied to the data item, because `@State`'s lifetime follows the *cell*, not the *model*. There is no pure-`@State` way to persist per-item state across reuse — the state must live somewhere whose lifetime matches the item. That place is the **model**.

So when a cell needs mutable, persistent state (selection, like, expand/collapse, …), make the model the source of truth: adopt `ObservableObject`, mark the state `@Published`, and observe it from the cell with `@ObservedObject`.

```swift
import SwiftUI
import Combine
import DynamicCollectionView

// ✅ State lives on the model — survives reuse, stays bound to the right item.
final class ProductItem: CellViewConfigurableModel, ObservableObject {
    typealias CellViewType = ProductCell

    let id: String
    let title: String
    @Published var isLiked = false          // mutable, persistent state

    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

struct ProductCell: CellView {
    @ObservedObject private var model: ProductItem   // observe the model, not @State

    init(model: ProductItem, indexPath: IndexPath) {
        self.model = model
    }

    var body: some View {
        HStack {
            Text(model.title)
            Spacer()
            Button {
                model.isLiked.toggle()       // write back to the SOT
            } label: {
                Image(systemName: model.isLiked ? "heart.fill" : "heart")
            }
            .buttonStyle(.plain)
        }
    }
}
```

A model that only feeds **immutable** data into its cell does not need any of this — keep it a plain `final class`. Adopt `ObservableObject` only when the cell actually mutates and must remember state.

> The same rule applies to `ReusableView` (headers/footers): they are reused too, so keep their state on the `ReusableViewConfigurableModel`.

### Defining a section & displaying it

Define a section via `SectionContext` and pass the section array to `DynamicCollectionView`. Sections are best kept as **value types (struct)** (copy-then-mutate is safe).

```swift
struct ColorSection: SectionContext {
    let id: String
    var items: [any CellViewConfigurableModel]
    var reusableItems: [String: [any ReusableViewConfigurableModel]] = [:]

    init(id: String, items: [ColorItem]) {
        self.id = id
        self.items = items
    }

    // full-width 64pt row grid
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

There are two `init`s: **value** and **binding**. Use the binding init when you want to pass `@State` (etc.) with `$`; behavior is identical to the value init (it reads the current value on every update).

```swift
@State private var sections: [any SectionContext] = ...

DynamicCollectionView(sections)    // value
DynamicCollectionView($sections)   // binding
```

### Grid layout

Putting N `GridItemLayout`s of width 1/N inside an `HGroupLayout` yields an N-column grid.

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

### Nested groups (group within a group)

Since `GroupLayout` conforms to `ItemLayout`, you can place **another group** as a subitem to express complex CompositionalLayouts. Below is a magazine layout of the form **horizontal group = [one large item (2/3)] + [vertical group (1/3): two small items]**.

```swift
var layout: some SectionLayout {
    GridSectionLayout(body: { _, _ in
        // horizontal group: large item on the left + vertical group on the right
        HGroupLayout(width: .fractionalWidth(1.0), height: .absolute(200)) {
            GridItemLayout(width: .fractionalWidth(2.0 / 3.0), height: .fractionalHeight(1.0))

            // group within a group: two small items stacked vertically
            VGroupLayout(width: .fractionalWidth(1.0 / 3.0), height: .fractionalHeight(1.0)) {
                GridItemLayout(width: .fractionalWidth(1.0), height: .fractionalHeight(0.5))
                GridItemLayout(width: .fractionalWidth(1.0), height: .fractionalHeight(0.5))
            }
        }
    })
    .interGroupSpacing(6)
}
```

This group (3 items) repeats vertically for the length of the data. The result looks like this (one large + two small items per row):

```
┌─────────────────┬───────┐
│                 │ small │
│   large item    ├───────┤
│                 │ small │
└─────────────────┴───────┘
```

> You can nest `HGroupLayout` / `VGroupLayout` to any depth. Every group except `WaterFallGroupLayout` is an `ItemLayout`, so it can be placed as a subitem anywhere.

### List layout

`ListSectionLayout` draws self-sizing rows based on `UICollectionLayoutListConfiguration`.

```swift
var layout: some SectionLayout {
    ListSectionLayout(.plain)   // .plain / .grouped / .insetGrouped …
}
```

### WaterFall layout

Build a Pinterest-style variable-height layout with `WaterFallGroupLayout`. Provide each item's height via `itemHeightContext`.

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

### Carousel (horizontal paging)

Use `GridSectionLayout.orthogonalScrollingBehavior(_:)` for a horizontally scrolling carousel. A group width under 1.0 lets neighboring cards peek in.

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

Supplementary views follow the same pattern as cells. Define `ReusableViewConfigurableModel` + `ReusableView`, and distinguish header/footer via `static var elementKind`.

```swift
// header model + view
final class SectionHeaderModel: ReusableViewConfigurableModel {
    typealias ReusableViewType = SectionHeaderView
    let id: String
    let title: String
    init(id: String, title: String) { self.id = id; self.title = title }
}

struct SectionHeaderView: ReusableView {
    static var elementKind: ReusableViewElementKind { .header }   // .footer also possible
    private let model: SectionHeaderModel
    init(model: SectionHeaderModel, indexPath: IndexPath) { self.model = model }
    var body: some View {
        HStack { Text(model.title).font(.headline); Spacer() }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.15))
    }
}

// In the section, wire reusableItems + the layout's header/footer closures
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

### Multiple sections

Pass sections with different layouts to `DynamicCollectionView`, and each section renders with its own layout.

```swift
let sections: [any SectionContext] = [
    CarouselSection(id: "banner",  items: banners),     // horizontal carousel
    GridSection(id: "grid",        items: products),    // 3-column grid
    ListSection(id: "list",        items: rows)         // list
]

DynamicCollectionView(sections)
```

### Event handlers

Receive selection / display events via chaining modifiers. Handlers are refreshed on every update, so they are always called with **the latest state**.

```swift
DynamicCollectionView(sections)
    .didSelectItem { item, indexPath in
        guard let item = item as? ColorItem else { return }
        print("selected: \(item.title) @ \(indexPath)")
    }
    .willDisplayItem { item, indexPath in
        // just before a cell appears (impression logging, pagination, etc.)
    }
    .willDisplayReusableItem { item, indexPath in
        // just before a header/footer appears
    }
    .keyboardDismissMode(.onDrag)   // dismiss the keyboard on scroll
```

### Pagination (infinite scroll)

Detect that a near-last item is about to be displayed in `willDisplayItem` and load the next page. Because it's declarative, **merging new data and rebuilding sections** makes the diff animate only the additions.

```swift
struct FeedView: View {
    @State private var items: [ColorItem] = []

    private var sections: [any SectionContext] {
        [GridSection(id: "feed", items: items)]
    }

    var body: some View {
        DynamicCollectionView(sections)
            .willDisplayItem { _, indexPath in
                if indexPath.item >= items.count - 3 {   // reached 3rd-from-last
                    loadNextPage()
                }
            }
            .onAppear { loadNextPage() }
    }

    private func loadNextPage() {
        // load asynchronously, then merge on the main thread
        items.append(contentsOf: nextPageItems())
    }
}
```

### Updating data (declarative)

Updating data needs no special API — **just change `sections` (or the state it derives from)**. The `id`-based diff animates insertions/deletions/moves automatically.

```swift
struct EditableView: View {
    // The real state is items (cell data); sections are derived from it.
    @State private var items: [ColorItem] = ColorItem.sample()

    private var sections: [any SectionContext] {
        [ColorSection(id: "main", items: items)]
    }

    var body: some View {
        VStack {
            HStack {
                Button("Add")     { items.append(ColorItem.random()) }   // insert animation
                Button("Shuffle") { items.shuffle() }                    // move animation
                Button("Clear")   { items.removeAll() }                  // delete animation
            }
            DynamicCollectionView(sections)
        }
    }
}
```

---

## Using in UIKit

You can use the engine (`UIDynamicCollectionView`) directly in a view controller, without SwiftUI. In that case implement **`UICell` / `UICellConfigurableModel` / `UISection`** instead of the SwiftUI protocols. The layout is returned directly as an `NSCollectionLayoutSection` from `UISection.sectionLayout(...)`.

### Defining cell / model / section

```swift
import UIKit
import DynamicCollectionView

// 1) Cell — UICollectionViewCell + UICell
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

// 2) Cell model — UICellConfigurableModel (mapped to the cell above via CellType)
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

// 3) Section — UISection (returns an NSCollectionLayoutSection directly)
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

### Using UIDynamicCollectionView

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

> Registration of cell components is handled automatically on `apply`/`append`, so no manual registration code is needed.

### Incremental update API

```swift
// apply everything (DiffableDataSource snapshot)
collectionView.apply(sections: sections, animated: true)

// incremental append of sections / items (pagination)
collectionView.append(sections: moreSections, animated: true)
collectionView.append(items: moreItems, at: "main", animated: true)

// reload a specific section
collectionView.reloadSection(["main"])
```

---

## Layout DSL reference

> The layout DSL is used in the SwiftUI `SectionContext.layout`. (UIKit `UISection` returns an `NSCollectionLayoutSection` directly.)

| Type | Kind | Description |
|---|---|---|
| `GridSectionLayout` | SectionLayout | General grid. Supports `header` / `body` / `footer` closures, `interGroupSpacing`, `contentInsets`, `orthogonalScrollingBehavior`, `visibleItem` |
| `ListSectionLayout` | SectionLayout | List based on `UICollectionLayoutListConfiguration`. Supports `contentInset` |
| `HGroupLayout` / `VGroupLayout` | GroupLayout | Horizontal / vertical group. Compose subitems via `@ItemLayoutBuilder` (groups can be nested) |
| `WaterFallGroupLayout` | GroupLayout | Pinterest-style variable height (`NSCollectionLayoutGroup.custom`) |
| `GridItemLayout` | ItemLayout | Single item (width × height) |
| `ReusableItemLayout` | ReusableLayout | Header/footer boundary item (`kind` + height) |

### `LayoutSize`

```swift
.fractionalWidth(0.5)    // 50% of the container width
.fractionalHeight(1.0)   // 100% of the container height
.estimated(120)          // estimated (auto-adjusts to content)
.absolute(64)            // fixed 64pt
```

### `OrthogonalScrollingBehavior`

`.none` · `.continuous` · `.continuousGroupLeadingBoundary` · `.paging` · `.groupPaging` · `.groupPagingCentered`

---

## License

[MIT](LICENSE)
