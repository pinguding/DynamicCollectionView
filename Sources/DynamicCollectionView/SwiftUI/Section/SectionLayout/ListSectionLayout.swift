import SwiftUI

/// 리스트 섹션의 외형을 지정하는 타입.
///
/// `UICollectionLayoutListConfiguration.Appearance` 의 별칭으로,
/// `.plain`, `.grouped`, `.insetGrouped` 등 리스트 스타일을 표현한다.
public typealias ListSectionAppearance = UICollectionLayoutListConfiguration.Appearance

/// `UICollectionLayoutListConfiguration` 기반의 리스트형 섹션 레이아웃을 구성하는 ``SectionLayout``.
///
/// 외형(``ListSectionAppearance``)과 함께 헤더/푸터를 ``ReusableLayout`` 으로 선언한다.
/// `contentInset(_:)` 빌더는 인셋을 적용한 복제본을 반환한다.
///
/// ```swift
/// let layout = ListSectionLayout(
///     .insetGrouped,
///     header: { _, _ in ReusableItemLayout(kind: .header, height: .estimated(44)) }
/// )
/// .contentInset(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
/// ```
public struct ListSectionLayout: SectionLayout {

    private let appearance: ListSectionAppearance

    private let header: (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]?

    private let footer: (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]?

    private var contentInset: EdgeInsets = .init(.zero)

    /// 외형과 헤더/푸터 클로저로 리스트 섹션 레이아웃을 생성한다.
    ///
    /// - Parameters:
    ///   - appearance: 리스트 섹션의 외형.
    ///   - header: 섹션 헤더 재사용 뷰를 만드는 클로저. 기본값은 헤더 없음(`nil`).
    ///   - footer: 섹션 푸터 재사용 뷰를 만드는 클로저. 기본값은 푸터 없음(`nil`).
    public init(
        _ appearance: ListSectionAppearance,
        @ReusableViewLayoutBuilder header: @escaping (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]? = { _, _ in nil },
        @ReusableViewLayoutBuilder footer: @escaping (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]? = { _, _ in nil }
    ) {
        self.appearance = appearance
        self.header = header
        self.footer = footer
    }

    /// 섹션 콘텐츠 인셋을 설정한 복제본을 반환한다.
    ///
    /// - Parameter inset: 섹션 가장자리 여백.
    /// - Returns: 인셋이 적용된 새 ``ListSectionLayout``.
    public func contentInset(_ inset: EdgeInsets) -> Self {
        var copiedSelf = self
        copiedSelf.contentInset = inset
        return copiedSelf
    }
}

extension ListSectionLayout {
    /// 리스트 구성과 헤더/푸터를 합쳐 `NSCollectionLayoutSection` 을 빌드한다.
    ///
    /// 헤더/푸터 모드를 보조 뷰(`.supplementary`)로 설정한 리스트 섹션을 만든다.
    ///
    /// - Parameters:
    ///   - index: 변환 대상 섹션의 인덱스.
    ///   - environment: 레이아웃 계산에 사용할 환경.
    /// - Returns: 빌드된 `NSCollectionLayoutSection`.
    /// - Note: DSL 내부 빌드용 SPI 다. 프레임워크가 `NSCollectionLayout*` 로 변환할 때 호출하며 직접 호출하지 말 것.
    public func _buildSectionLayout(index: Int, environment: CollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var configuration = UICollectionLayoutListConfiguration(appearance: self.appearance)
        configuration.headerMode = .supplementary
        configuration.footerMode = .supplementary
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)

        var supplementaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []

        if let header = self.header(index, environment) {
            supplementaryItems.append(contentsOf: header.map { $0._buildSupplementaryLayout() })
        }
        if let footer = self.footer(index, environment) {
            supplementaryItems.append(contentsOf: footer.map { $0._buildSupplementaryLayout() })
        }

        section.contentInsets = .init(self.contentInset)
        section.boundarySupplementaryItems = supplementaryItems

        return section
    }
}
