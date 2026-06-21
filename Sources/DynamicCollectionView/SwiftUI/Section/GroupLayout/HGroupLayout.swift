import UIKit

/// 하위 아이템들을 가로로 배치하는 ``GroupLayout``.
///
/// 너비/높이/간격과 함께 ``ItemLayoutBuilder`` 로 하위 ``ItemLayout`` 을 선언하면
/// 가로 방향 `NSCollectionLayoutGroup` 으로 변환된다.
public class HGroupLayout {

    private let width: LayoutSize

    private let height: LayoutSize

    private let spacing: CGFloat

    private let items: () -> [any ItemLayout]

    /// 크기/간격과 하위 아이템 빌더로 가로 그룹을 생성한다.
    ///
    /// - Parameters:
    ///   - width: 그룹 너비 치수.
    ///   - height: 그룹 높이 치수.
    ///   - spacing: 하위 아이템 사이 간격(포인트). 기본값은 `0`.
    ///   - items: 하위 ``ItemLayout`` 들을 선언하는 빌더 클로저.
    public init(width: LayoutSize, height: LayoutSize, spacing: CGFloat = 0, @ItemLayoutBuilder items: @escaping () -> [any ItemLayout]) {
        self.width = width
        self.height = height
        self.spacing = spacing
        self.items = items
    }
}

extension HGroupLayout: GroupLayout {

    /// 하위 아이템들을 가로로 배치한 `NSCollectionLayoutGroup` 을 빌드한다.
    ///
    /// - Returns: 빌드된 가로 방향 `NSCollectionLayoutGroup`.
    /// - Note: DSL 내부 빌드용 SPI 다. 프레임워크가 `NSCollectionLayout*` 로 변환할 때 호출하며 직접 호출하지 말 것.
    public final func _buildGroupLayout() -> NSCollectionLayoutGroup {

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: self.width.nsCollectionLayoutDimension,
                heightDimension: self.height.nsCollectionLayoutDimension
            ),
            subitems: self.items().map { $0._buildItemLayout() }
        )

        group.interItemSpacing = .fixed(self.spacing)

        return group
    }
}
