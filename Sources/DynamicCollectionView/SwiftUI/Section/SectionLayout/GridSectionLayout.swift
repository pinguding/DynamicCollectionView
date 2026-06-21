import SwiftUI

/// 섹션의 직교(가로) 스크롤 동작을 정의하는 열거형.
///
/// `UICollectionLayoutSectionOrthogonalScrollingBehavior` 로 매핑되며,
/// ``GridSectionLayout/orthogonalScrollingBehavior(_:)`` 에 전달한다.
public enum OrthogonalScrollingBehavior {
    /// 직교 스크롤을 사용하지 않는다.
    case none
    /// 자유롭게 연속 스크롤한다.
    case continuous
    /// 연속 스크롤하되 그룹의 선두 경계에 정렬한다.
    case continuousGroupLeadingBoundary
    /// 컨테이너 단위로 페이징한다.
    case paging
    /// 그룹 단위로 페이징한다.
    case groupPaging
    /// 그룹 단위로 페이징하며 가운데 정렬한다.
    case groupPagingCentered

    /// 대응하는 `UICollectionLayoutSectionOrthogonalScrollingBehavior` 로 변환한 값.
    var uiCollectionLayoutSectionOrthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior {
        switch self {
        case .none:
            return .none
        case .continuous:
            return .continuous
        case .continuousGroupLeadingBoundary:
            return .continuousGroupLeadingBoundary
        case .paging:
            return .paging
        case .groupPaging:
            return .groupPaging
        case .groupPagingCentered:
            return .groupPagingCentered
        }
    }
}

/// 헤더/본문/푸터 클로저로 그리드형 섹션 레이아웃을 구성하는 ``SectionLayout``.
///
/// 본문 그룹은 ``GroupLayout`` 으로, 헤더/푸터는 ``ReusableLayout`` 으로 선언한다.
/// `interGroupSpacing(_:)`, `contentInsets(_:)`, `orthogonalScrollingBehavior(_:)`,
/// `visibleItem(_:)` 빌더는 각각 변경을 적용한 복제본을 반환한다.
///
/// ```swift
/// let layout = GridSectionLayout(
///     header: { _, _ in ReusableItemLayout(kind: .header, height: .absolute(44)) },
///     body: { _, _ in
///         HGroupLayout(width: .fractionalWidth(1.0), height: .absolute(120)) {
///             GridItemLayout(width: .fractionalWidth(0.5), height: .fractionalHeight(1.0))
///         }
///     }
/// )
/// .interGroupSpacing(8)
/// .orthogonalScrollingBehavior(.groupPaging)
/// ```
public struct GridSectionLayout {

    private let header: (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]?

    private let body: (_ index: Int, _ environment: CollectionLayoutEnvironment) -> any GroupLayout

    private let footer: (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]?

    private var interGroupSpacing: CGFloat = 0

    private var contentInsets: EdgeInsets = .init(.zero)

    private var orthogonalScrollingBehavior: OrthogonalScrollingBehavior = .none

    private var visibleItemsInvalidationHandler: (([any CollectionVisibleItem], CGPoint, any CollectionLayoutEnvironment) -> Void)? = nil

    /// 헤더/본문/푸터 클로저로 그리드 섹션 레이아웃을 생성한다.
    ///
    /// - Parameters:
    ///   - header: 섹션 헤더 재사용 뷰를 만드는 클로저. 기본값은 헤더 없음(`nil`).
    ///   - body: 섹션 본문 그룹을 만드는 클로저.
    ///   - footer: 섹션 푸터 재사용 뷰를 만드는 클로저. 기본값은 푸터 없음(`nil`).
    public init(
        @ReusableViewLayoutBuilder header: @escaping (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]? = { _, _ in nil },
        body: @escaping (_ index: Int, _ environment: CollectionLayoutEnvironment) -> any GroupLayout,
        @ReusableViewLayoutBuilder footer: @escaping (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]? = { _, _ in nil }
    ) {
        self.header = header
        self.body = body
        self.footer = footer
    }

    /// 그룹 간 간격을 설정한 복제본을 반환한다.
    ///
    /// - Parameter spacing: 그룹 사이의 간격(포인트).
    /// - Returns: 간격이 적용된 새 ``GridSectionLayout``.
    public func interGroupSpacing(_ spacing: CGFloat) -> Self {
        var copiedSelf = self
        copiedSelf.interGroupSpacing = spacing
        return copiedSelf
    }

    /// 섹션 콘텐츠 인셋을 설정한 복제본을 반환한다.
    ///
    /// - Parameter insets: 섹션 가장자리 여백.
    /// - Returns: 인셋이 적용된 새 ``GridSectionLayout``.
    public func contentInsets(_ insets: EdgeInsets) -> Self {
        var copiedSelf = self
        copiedSelf.contentInsets = insets
        return copiedSelf
    }

    /// 직교 스크롤 동작을 설정한 복제본을 반환한다.
    ///
    /// - Parameter behavior: 적용할 ``OrthogonalScrollingBehavior``.
    /// - Returns: 스크롤 동작이 적용된 새 ``GridSectionLayout``.
    public func orthogonalScrollingBehavior(_ behavior: OrthogonalScrollingBehavior) -> Self {
        var copiedSelf = self
        copiedSelf.orthogonalScrollingBehavior = behavior
        return copiedSelf
    }

    /// 가시 아이템 무효화 핸들러를 설정한 복제본을 반환한다.
    ///
    /// 스크롤에 따라 보이는 아이템을 추적하거나 변형(시차 효과 등)할 때 사용한다.
    ///
    /// - Parameter handler: 가시 아이템 목록과 오프셋, 환경을 전달받는 핸들러.
    /// - Returns: 핸들러가 적용된 새 ``GridSectionLayout``.
    public func visibleItem(_ handler: @escaping ([any CollectionVisibleItem], CGPoint, any CollectionLayoutEnvironment) -> Void) -> Self {
        var copiedSelf = self
        copiedSelf.visibleItemsInvalidationHandler = handler
        return copiedSelf
    }
}

extension GridSectionLayout: SectionLayout {
    /// 헤더/본문/푸터와 설정값을 합쳐 `NSCollectionLayoutSection` 을 빌드한다.
    ///
    /// - Parameters:
    ///   - index: 변환 대상 섹션의 인덱스.
    ///   - environment: 레이아웃 계산에 사용할 환경.
    /// - Returns: 빌드된 `NSCollectionLayoutSection`.
    /// - Note: DSL 내부 빌드용 SPI 다. 프레임워크가 `NSCollectionLayout*` 로 변환할 때 호출하며 직접 호출하지 말 것.
    public func _buildSectionLayout(index: Int, environment: CollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let group = self.body(index, environment)._buildGroupLayout()

        var supplementaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []

        if let header = self.header(index, environment) {
            supplementaryItems.append(contentsOf: header.map { $0._buildSupplementaryLayout() })
        }
        if let footer = self.footer(index, environment) {
            supplementaryItems.append(contentsOf: footer.map { $0._buildSupplementaryLayout() })
        }

        let section = NSCollectionLayoutSection(group: group)

        section.boundarySupplementaryItems = supplementaryItems

        section.interGroupSpacing = self.interGroupSpacing
        section.contentInsets = .init(self.contentInsets)
        section.orthogonalScrollingBehavior = self.orthogonalScrollingBehavior.uiCollectionLayoutSectionOrthogonalScrollingBehavior
        section.visibleItemsInvalidationHandler = self.visibleItemsInvalidationHandler

        return section
    }
}
