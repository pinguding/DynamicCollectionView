import UIKit

/// 단일 셀의 크기를 정의하는 아이템 레이아웃.
///
/// 너비/높이를 ``LayoutSize`` 로 받아 하나의 `NSCollectionLayoutItem` 을 만든다.
/// 보통 ``HGroupLayout`` 이나 ``VGroupLayout`` 의 하위 아이템으로 사용한다.
public class GridItemLayout {

    private let width: LayoutSize

    private let height: LayoutSize

    /// 너비와 높이를 지정해 아이템 레이아웃을 생성한다.
    ///
    /// - Parameters:
    ///   - width: 아이템 너비 치수.
    ///   - height: 아이템 높이 치수.
    public init(width: LayoutSize, height: LayoutSize) {
        self.width = width
        self.height = height
    }
}

extension GridItemLayout: ItemLayout {

    /// 지정한 너비/높이로 `NSCollectionLayoutItem` 을 빌드한다.
    ///
    /// - Returns: 빌드된 `NSCollectionLayoutItem`.
    /// - Note: DSL 내부 빌드용 SPI 다. 프레임워크가 `NSCollectionLayout*` 로 변환할 때 호출하며 직접 호출하지 말 것.
    public final func _buildItemLayout() -> NSCollectionLayoutItem {
        .init(layoutSize: .init(
            widthDimension: self.width.nsCollectionLayoutDimension,
            heightDimension: self.height.nsCollectionLayoutDimension
        ))
    }
}
