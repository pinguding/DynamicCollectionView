import SwiftUI

/// Pinterest 식 가변 높이(워터폴) 레이아웃을 구성하는 ``GroupLayout``.
///
/// 컬럼 수와 아이템 수, 그리고 각 아이템의 높이를 산출하는 컨텍스트 클로저를 받아
/// 가장 짧은 컬럼에 다음 아이템을 채워 넣는 방식으로 프레임을 계산하고,
/// `NSCollectionLayoutGroup.custom` 으로 변환한다. `interItemSpacing(_:)` 로 간격을 조정한다.
///
/// ```swift
/// let layout = WaterFallGroupLayout(
///     numberOfColumn: 2,
///     numberOfItems: models.count,
///     environment: environment,
///     contentInset: .init(top: 8, leading: 8, bottom: 8, trailing: 8)
/// ) { index, itemWidth in
///     models[index].estimatedHeight(forWidth: itemWidth)
/// }
/// .interItemSpacing(8)
/// ```
public class WaterFallGroupLayout: GroupLayout {

    private let width: LayoutSize

    private let numberOfColumn: Int

    private let numberOfItems: Int

    private let environment: CollectionLayoutEnvironment

    private let itemHeightContext: (_ itemIndex: Int, _ itemWidth: CGFloat) -> CGFloat

    private var interItemSpacing: CGFloat = 0

    private var columnHeights: [CGFloat]

    private var contentInset: EdgeInsets

    /// 컬럼/아이템 수와 높이 컨텍스트로 워터폴 그룹을 생성한다.
    ///
    /// - Parameters:
    ///   - width: 그룹 너비 치수. 기본값은 컨테이너 전체 너비(`.fractionalWidth(1.0)`).
    ///   - numberOfColumn: 컬럼(열) 수.
    ///   - numberOfItems: 배치할 아이템 수.
    ///   - environment: 컨테이너 크기를 얻기 위한 레이아웃 환경.
    ///   - contentInset: 그룹 가장자리 여백. 기본값은 여백 없음.
    ///   - itemHeightContext: 아이템 인덱스와 계산된 아이템 너비를 받아 높이를 반환하는 클로저.
    public init(
        width: LayoutSize = .fractionalWidth(1.0),
        numberOfColumn: Int,
        numberOfItems: Int,
        environment: CollectionLayoutEnvironment,
        contentInset: EdgeInsets = .init(.zero),
        itemHeightContext: @escaping (_ itemIndex: Int, _ itemWidth: CGFloat) -> CGFloat
    ) {
        self.width = width
        self.numberOfColumn = numberOfColumn
        self.numberOfItems = numberOfItems
        self.environment = environment
        self.itemHeightContext = itemHeightContext
        self.columnHeights = .init(repeating: contentInset.top, count: numberOfColumn)
        self.contentInset = contentInset
    }

    /// 계산된 커스텀 아이템들로 `NSCollectionLayoutGroup` 을 빌드한다.
    ///
    /// 그룹의 높이는 가장 높은 컬럼의 누적 높이로 결정된다.
    ///
    /// - Returns: 빌드된 커스텀 `NSCollectionLayoutGroup`.
    /// - Note: DSL 내부 빌드용 SPI 다. 프레임워크가 `NSCollectionLayout*` 로 변환할 때 호출하며 직접 호출하지 말 것.
    public final func _buildGroupLayout() -> NSCollectionLayoutGroup {
        let items = self._buildCustomItemLayout()
        return NSCollectionLayoutGroup.custom(
            layoutSize: .init(
                widthDimension: self.width.nsCollectionLayoutDimension,
                heightDimension: .absolute(self.maxColumnHeight())
            )) { environment in
                return items
            }
    }

    /// 아이템 간 간격을 설정하고 자신을 반환한다.
    ///
    /// - Parameter spacing: 아이템 사이 간격(포인트).
    /// - Returns: 간격이 적용된 자신(`Self`).
    public func interItemSpacing(_ spacing: CGFloat) -> Self {
        self.interItemSpacing = spacing
        return self
    }
}

private extension WaterFallGroupLayout {

    func _buildCustomItemLayout() -> [NSCollectionLayoutGroupCustomItem] {
        let containerWidth = self.environment.container.effectiveContentSize.width
        let itemWidth = (containerWidth - (self.contentInset.leading + self.contentInset.trailing) - (CGFloat(self.numberOfColumn) - 1) * self.interItemSpacing) / CGFloat(self.numberOfColumn)

        var items: [NSCollectionLayoutGroupCustomItem] = []
        for i in 0 ..< self.numberOfItems {
            let itemHeight = self.itemHeightContext(i, itemWidth)
            let size = CGSize(width: itemWidth, height: itemHeight)
            let origin = self.itemOrigin(itemWidth: itemWidth)
            let itemFrame = CGRect(origin: origin, size: size)
            self.columnHeights[minHeightColumnIndex()] = itemFrame.maxY + self.interItemSpacing
            items.append(.init(frame: itemFrame))
        }
        return items
    }

    func maxColumnHeight() -> CGFloat {
        return self.columnHeights.max() ?? 0
    }

    func itemOrigin(itemWidth: CGFloat) -> CGPoint {
        let index = self.minHeightColumnIndex()
        let x = (itemWidth + self.interItemSpacing) * CGFloat(index) + self.contentInset.leading
        let y = self.columnHeights[index].rounded()
        return .init(x: x, y: y)
    }

    func minHeightColumnIndex() -> Int {
        self.columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
    }
}
