import UIKit

/// 헤더 또는 푸터 재사용 뷰의 레이아웃을 정의하는 아이템 레이아웃.
///
/// ``ReusableViewElementKind`` 와 높이를 받아
/// `NSCollectionLayoutBoundarySupplementaryItem` 을 만든다. 너비는 항상 컨테이너에 꽉 찬다.
public class ReusableItemLayout {

    private let height: LayoutSize

    private let kind: ReusableViewElementKind

    /// 종류와 높이를 지정해 재사용 뷰 레이아웃을 생성한다.
    ///
    /// - Parameters:
    ///   - kind: 재사용 뷰 종류(`.header` 또는 `.footer`).
    ///   - height: 재사용 뷰 높이 치수.
    public init(kind: ReusableViewElementKind, height: LayoutSize) {
        self.height = height
        self.kind = kind
    }
}

extension ReusableItemLayout: ReusableLayout {

    /// 종류와 높이에 맞춰 경계 보조 아이템을 빌드한다.
    ///
    /// 헤더면 상단(`.top`), 푸터면 하단(`.bottom`) 정렬로 배치된다.
    ///
    /// - Returns: 빌드된 `NSCollectionLayoutBoundarySupplementaryItem`.
    /// - Note: DSL 내부 빌드용 SPI 다. 프레임워크가 `NSCollectionLayout*` 로 변환할 때 호출하며 직접 호출하지 말 것.
    public final func _buildSupplementaryLayout() -> NSCollectionLayoutBoundarySupplementaryItem {
        .init(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: self.height.nsCollectionLayoutDimension
            ),
            elementKind: self.kind.rawValue,
            alignment: self.kind == .header ? .top : .bottom
        )
    }
}
