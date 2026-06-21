import SwiftUI

/// A ``GroupLayout`` that builds a Pinterest-style variable-height (waterfall) layout.
///
/// It takes the number of columns, the number of items, and a context closure that computes each item's height,
/// then calculates frames by placing each next item into the shortest column,
/// and converts the result into an `NSCollectionLayoutGroup.custom`. Spacing is adjusted with `interItemSpacing(_:)`.
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

    /// Creates a waterfall group from the column/item counts and a height context.
    ///
    /// - Parameters:
    ///   - width: The group's width dimension. Defaults to the full container width (`.fractionalWidth(1.0)`).
    ///   - numberOfColumn: The number of columns.
    ///   - numberOfItems: The number of items to lay out.
    ///   - environment: The layout environment used to obtain the container size.
    ///   - contentInset: The group's edge insets. Defaults to no insets.
    ///   - itemHeightContext: A closure that takes the item index and the computed item width and returns the height.
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

    /// Builds an `NSCollectionLayoutGroup` from the computed custom items.
    ///
    /// The group's height is determined by the cumulative height of the tallest column.
    ///
    /// - Returns: The built custom `NSCollectionLayoutGroup`.
    /// - Note: This is an internal build SPI for the DSL. The framework calls it when converting to `NSCollectionLayout*`; do not call it directly.
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

    /// Sets the inter-item spacing and returns itself.
    ///
    /// - Parameter spacing: The spacing between items, in points.
    /// - Returns: Itself (`Self`) with the spacing applied.
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
