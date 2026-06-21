import SwiftUI

/// 섹션 단위 레이아웃을 정의하는 프로토콜.
///
/// ``GridSectionLayout``, ``ListSectionLayout`` 이 채택하며,
/// 레이아웃 DSL 계층의 최상위(섹션 레벨)에 해당한다.
public protocol SectionLayout {
    /// 섹션 레이아웃을 `NSCollectionLayoutSection` 으로 변환한다.
    ///
    /// - Parameters:
    ///   - index: 변환 대상 섹션의 인덱스.
    ///   - environment: 레이아웃 계산에 사용할 환경.
    /// - Returns: 빌드된 `NSCollectionLayoutSection`.
    /// - Note: DSL 내부 빌드용 SPI 다. 프레임워크가 `NSCollectionLayout*` 로 변환할 때 호출하며 직접 호출하지 말 것.
    func _buildSectionLayout(index: Int, environment: CollectionLayoutEnvironment) -> NSCollectionLayoutSection
}

/// 그룹 단위 레이아웃을 정의하는 프로토콜.
///
/// ``ItemLayout`` 을 상속하며 ``HGroupLayout``, ``VGroupLayout``, ``WaterFallGroupLayout`` 이 채택한다.
public protocol GroupLayout: ItemLayout {
    /// 그룹 레이아웃을 `NSCollectionLayoutGroup` 으로 변환한다.
    ///
    /// - Returns: 빌드된 `NSCollectionLayoutGroup`.
    /// - Note: DSL 내부 빌드용 SPI 다. 프레임워크가 `NSCollectionLayout*` 로 변환할 때 호출하며 직접 호출하지 말 것.
    func _buildGroupLayout() -> NSCollectionLayoutGroup
}

public extension GroupLayout {
    /// ``ItemLayout/_buildItemLayout()`` 요구사항을 그룹 빌드로 충족하는 기본 구현.
    ///
    /// - Returns: 그룹을 `NSCollectionLayoutItem` 으로 업캐스트한 값.
    /// - Note: DSL 내부 빌드용 SPI 다. 직접 호출하지 말 것.
    func _buildItemLayout() -> NSCollectionLayoutItem {
        self._buildGroupLayout() as NSCollectionLayoutItem
    }
}

/// 재사용 뷰(헤더/푸터) 레이아웃을 정의하는 프로토콜.
///
/// ``ItemLayout`` 을 상속하며 ``ReusableItemLayout`` 이 채택한다.
public protocol ReusableLayout: ItemLayout {
    /// 재사용 뷰 레이아웃을 `NSCollectionLayoutBoundarySupplementaryItem` 으로 변환한다.
    ///
    /// - Returns: 빌드된 경계 보조 아이템.
    /// - Note: DSL 내부 빌드용 SPI 다. 프레임워크가 `NSCollectionLayout*` 로 변환할 때 호출하며 직접 호출하지 말 것.
    func _buildSupplementaryLayout() -> NSCollectionLayoutBoundarySupplementaryItem
}

public extension ReusableLayout {

    /// ``ItemLayout/_buildItemLayout()`` 요구사항을 보조 아이템 빌드로 충족하는 기본 구현.
    ///
    /// - Returns: 보조 아이템을 `NSCollectionLayoutItem` 으로 업캐스트한 값.
    /// - Note: DSL 내부 빌드용 SPI 다. 직접 호출하지 말 것.
    func _buildItemLayout() -> NSCollectionLayoutItem {
        self._buildSupplementaryLayout() as NSCollectionLayoutItem
    }
}

/// 아이템 단위 레이아웃을 정의하는 프로토콜.
///
/// 레이아웃 DSL 계층의 기본 단위로, ``GridItemLayout`` 이 채택하며
/// ``GroupLayout``, ``ReusableLayout`` 의 상위 프로토콜이다.
public protocol ItemLayout {
    /// 아이템 레이아웃을 `NSCollectionLayoutItem` 으로 변환한다.
    ///
    /// - Returns: 빌드된 `NSCollectionLayoutItem`.
    /// - Note: DSL 내부 빌드용 SPI 다. 프레임워크가 `NSCollectionLayout*` 로 변환할 때 호출하며 직접 호출하지 말 것.
    func _buildItemLayout() -> NSCollectionLayoutItem
}

/// 커스텀 가변 높이 아이템 레이아웃을 정의하는 프로토콜.
///
/// 워터폴처럼 직접 프레임을 계산하는 레이아웃이 채택한다.
public protocol CustomItemLayout {
    /// 커스텀 아이템 레이아웃을 `NSCollectionLayoutGroupCustomItem` 으로 변환한다.
    ///
    /// - Returns: 빌드된 커스텀 그룹 아이템.
    /// - Note: DSL 내부 빌드용 SPI 다. 프레임워크가 `NSCollectionLayout*` 로 변환할 때 호출하며 직접 호출하지 말 것.
    func _buildCustomItemLayout() -> NSCollectionLayoutGroupCustomItem
}
