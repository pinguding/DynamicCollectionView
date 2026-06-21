import SwiftUI

/// `UICollectionView` 를 감싸는 선언형 SwiftUI 래퍼.
///
/// 섹션 배열을 받아 컴포지셔널 레이아웃 기반의 컬렉션 뷰를 그립니다. 내부적으로
/// `UICollectionViewDiffableDataSource` 를 사용하므로, 부모 뷰의 상태가 바뀌어
/// 새 섹션 배열이 다시 전달되면 이전 스냅샷과의 차이를 계산해 항목의 추가/삭제/이동을
/// 자동으로 애니메이션합니다.
///
/// 선택/표시 등의 이벤트는 ``didSelectItem(_:)``, ``willDisplayItem(_:)``,
/// ``willDisplayReusableItem(_:)`` 같은 체이닝 모디파이어로 등록합니다. 이 핸들러들은
/// 구조체 값으로 저장되었다가 ``updateUIView(_:context:)`` 에서 매 업데이트마다
/// `context.coordinator` 에 다시 주입되므로, 상태가 바뀌어도 항상 최신 클로저가
/// 호출됩니다.
///
/// ```swift
/// struct ContentView: View {
///     @State private var sections: [any SectionContext] = ...
///
///     var body: some View {
///         DynamicCollectionView(sections)
///             .didSelectItem { item, indexPath in
///                 print("선택됨: \(indexPath)")
///             }
///             .willDisplayItem { item, indexPath in
///                 // 페이지네이션 등
///             }
///             .keyboardDismissMode(.onDrag)
///     }
/// }
/// ```
///
/// - Note: 섹션은 내부에서 ``SwiftUISection`` 으로 감싸진 뒤 `UIDynamicCollectionView.apply` 로 전달됩니다.
public struct DynamicCollectionView: UIViewRepresentable {

    /// `UIViewRepresentable` 가 생성/관리하는 UIKit 뷰 타입.
    public typealias UIViewType = UIDynamicCollectionView

    /// 컬렉션 뷰의 델리게이트 이벤트를 중계하는 코디네이터 타입.
    public typealias Coordinator = Self.DynamicCollectionViewCoordinator

    private let sections: [any SectionContext]

    private let animatingDifferences: Bool

    private var itemDisplayHandler: ((_ item: any UICellConfigurableModel, _ indexPath: IndexPath) -> Void)?

    private var reusableItemDisplayHandler: ((_ item: any UIReusableViewConfigurableModel, _ indexPath: IndexPath) -> Void)?

    private var didSelectItemHandler: ((_ item: any UICellConfigurableModel, _ indexPath: IndexPath) -> Void)?

    private var keyboardDismissModeValue: UIScrollView.KeyboardDismissMode?

    /// 표시할 섹션 배열로 컬렉션 뷰를 생성합니다.
    ///
    /// 같은 컬렉션 뷰에 대해 부모 상태가 갱신되어 새 `sections` 가 전달되면, diffable
    /// 데이터 소스가 이전 스냅샷과의 차이를 계산해 변경 사항을 반영합니다.
    ///
    /// - Parameters:
    ///   - sections: 컬렉션 뷰에 표시할 섹션 목록.
    ///   - animatingDifferences: 스냅샷 적용 시 변경 사항을 애니메이션할지 여부. 기본값은 `true`.
    public init(_ sections: [any SectionContext], animatingDifferences: Bool = true) {
        self.sections = sections
        self.animatingDifferences = animatingDifferences
    }

    /// 델리게이트 이벤트를 처리할 ``DynamicCollectionViewCoordinator`` 를 생성합니다.
    ///
    /// - Returns: 새로 생성된 코디네이터 인스턴스.
    public func makeCoordinator() -> DynamicCollectionViewCoordinator {
        DynamicCollectionViewCoordinator()
    }

    /// 기반이 되는 ``UIDynamicCollectionView`` 를 생성하고 코디네이터를 델리게이트로 연결합니다.
    ///
    /// - Parameter context: 코디네이터 등 SwiftUI 가 제공하는 표현 컨텍스트.
    /// - Returns: 새로 생성된 UIKit 컬렉션 뷰.
    public func makeUIView(context: Context) -> UIDynamicCollectionView {
        let collectionView = UIDynamicCollectionView()
        collectionView.delegate = context.coordinator
        return collectionView
    }

    /// 최신 핸들러와 설정을 코디네이터에 주입하고 현재 섹션 스냅샷을 적용합니다.
    ///
    /// 모디파이어로 저장해 둔 클로저들을 매 업데이트마다 코디네이터에 다시 주입하여
    /// stale 클로저 문제를 방지하고, 섹션을 ``SwiftUISection`` 으로 감싸 컬렉션 뷰에
    /// 적용합니다.
    ///
    /// - Parameters:
    ///   - uiView: 갱신할 UIKit 컬렉션 뷰.
    ///   - context: 코디네이터를 포함한 표현 컨텍스트.
    public func updateUIView(_ uiView: UIDynamicCollectionView, context: Context) {
        context.coordinator.itemDisplayHandler = self.itemDisplayHandler
        context.coordinator.reusableItemDisplayHandler = self.reusableItemDisplayHandler
        context.coordinator.didSelectItemHandler = self.didSelectItemHandler
        if let mode = self.keyboardDismissModeValue {
            uiView.keyboardDismissMode = mode
        }

        uiView.apply(sections: self.sections.map { SwiftUISection($0) }, animated: self.animatingDifferences)
    }

    /// 셀이 화면에 표시되기 직전에 호출될 핸들러를 등록합니다.
    ///
    /// 무한 스크롤 페이지네이션이나 노출 로깅 등에 활용할 수 있습니다.
    ///
    /// - Parameter itemDisplayHandler: 표시될 모델과 인덱스 경로를 받는 클로저.
    /// - Returns: 핸들러가 적용된 새 ``DynamicCollectionView`` 값.
    public func willDisplayItem(_ itemDisplayHandler: @escaping (_ item: any UICellConfigurableModel, _ indexPath: IndexPath) -> Void) -> Self {
        var copy = self
        copy.itemDisplayHandler = itemDisplayHandler
        return copy
    }

    /// 서플먼터리 뷰(헤더/푸터)가 화면에 표시되기 직전에 호출될 핸들러를 등록합니다.
    ///
    /// - Parameter reusableItemDisplayHandler: 표시될 서플먼터리 모델과 인덱스 경로를 받는 클로저.
    /// - Returns: 핸들러가 적용된 새 ``DynamicCollectionView`` 값.
    public func willDisplayReusableItem(_ reusableItemDisplayHandler: @escaping (_ item: any UIReusableViewConfigurableModel, _ indexPath: IndexPath) -> Void) -> Self {
        var copy = self
        copy.reusableItemDisplayHandler = reusableItemDisplayHandler
        return copy
    }

    /// 스크롤 중 키보드를 닫는 방식을 설정합니다.
    ///
    /// - Parameter mode: 적용할 `UIScrollView.KeyboardDismissMode`.
    /// - Returns: 설정이 적용된 새 ``DynamicCollectionView`` 값.
    public func keyboardDismissMode(_ mode: UIScrollView.KeyboardDismissMode) -> Self {
        var copy = self
        copy.keyboardDismissModeValue = mode
        return copy
    }

    /// 항목이 선택되었을 때 호출될 핸들러를 등록합니다.
    ///
    /// - Parameter didSelectItemHandler: 선택된 모델과 인덱스 경로를 받는 클로저.
    /// - Returns: 핸들러가 적용된 새 ``DynamicCollectionView`` 값.
    public func didSelectItem(_ didSelectItemHandler: @escaping (_ item: any UICellConfigurableModel, _ indexPath: IndexPath) -> Void) -> Self {
        var copy = self
        copy.didSelectItemHandler = didSelectItemHandler
        return copy
    }
}

public extension DynamicCollectionView {
    /// ``DynamicCollectionView`` 의 UIKit 델리게이트 이벤트를 SwiftUI 핸들러로 중계하는 코디네이터.
    ///
    /// `UICollectionViewDelegate` 콜백을 받아, ``updateUIView(_:context:)`` 에서
    /// 주입된 최신 핸들러 클로저로 전달합니다. 인덱스 경로로 모델을 안전하게 조회한 뒤
    /// 해당 클로저가 있을 때만 호출합니다.
    class DynamicCollectionViewCoordinator: NSObject, UICollectionViewDelegate {

        var itemDisplayHandler: ((_ item: any UICellConfigurableModel, _ indexPath: IndexPath) -> Void)?

        var reusableItemDisplayHandler: ((_ item: any UIReusableViewConfigurableModel, _ indexPath: IndexPath) -> Void)?

        var didSelectItemHandler: ((_ item: any UICellConfigurableModel, _ indexPath: IndexPath) -> Void)?

        /// 셀이 표시되기 직전에 호출되어 등록된 표시 핸들러로 모델과 인덱스 경로를 전달합니다.
        ///
        /// - Parameters:
        ///   - collectionView: 이벤트를 보낸 컬렉션 뷰.
        ///   - cell: 표시될 셀.
        ///   - indexPath: 표시될 셀의 인덱스 경로.
        public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
            guard let collectionView = collectionView as? UIDynamicCollectionView,
                  let item = collectionView.currentSections[safe: indexPath.section]?.items[safe: indexPath.item]
            else { return }

            self.itemDisplayHandler?(item, indexPath)
        }

        /// 서플먼터리 뷰가 표시되기 직전에 호출되어 등록된 핸들러로 모델과 인덱스 경로를 전달합니다.
        ///
        /// - Parameters:
        ///   - collectionView: 이벤트를 보낸 컬렉션 뷰.
        ///   - view: 표시될 서플먼터리 뷰.
        ///   - elementKind: 서플먼터리 엘리먼트 종류(헤더/푸터).
        ///   - indexPath: 표시될 뷰의 인덱스 경로.
        public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
            guard let collectionView = collectionView as? UIDynamicCollectionView,
                  let item = collectionView.currentSections[safe: indexPath.section]?.reusableItems[elementKind]?[safe: indexPath.item]
            else { return }

            self.reusableItemDisplayHandler?(item, indexPath)
        }

        /// 항목이 선택되었을 때 호출되어 등록된 선택 핸들러로 모델과 인덱스 경로를 전달합니다.
        ///
        /// - Parameters:
        ///   - collectionView: 이벤트를 보낸 컬렉션 뷰.
        ///   - indexPath: 선택된 항목의 인덱스 경로.
        public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard let collectionView = collectionView as? UIDynamicCollectionView,
                  let item = collectionView.currentSections[safe: indexPath.section]?.items[safe: indexPath.item]
            else { return }

            self.didSelectItemHandler?(item, indexPath)
        }
    }
}
