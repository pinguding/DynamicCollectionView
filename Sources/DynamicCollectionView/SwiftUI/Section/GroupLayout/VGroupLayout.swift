import UIKit

/// A ``GroupLayout`` that arranges its subitems vertically.
///
/// When you declare subitem ``ItemLayout`` values with ``ItemLayoutBuilder`` along with the width/height/spacing,
/// it is converted into a vertical `NSCollectionLayoutGroup`.
public class VGroupLayout {

    private let width: LayoutSize

    private let height: LayoutSize

    private let spacing: CGFloat

    private let items: () -> [any ItemLayout]

    /// Creates a vertical group from the size/spacing and a subitem builder.
    ///
    /// - Parameters:
    ///   - width: The group's width dimension.
    ///   - height: The group's height dimension.
    ///   - spacing: The spacing between subitems, in points. Defaults to `0`.
    ///   - items: A builder closure that declares the subitem ``ItemLayout`` values.
    public init(width: LayoutSize, height: LayoutSize, spacing: CGFloat = 0, @ItemLayoutBuilder items: @escaping () -> [any ItemLayout]) {
        self.width = width
        self.height = height
        self.spacing = spacing
        self.items = items
    }
}

extension VGroupLayout: GroupLayout {

    /// Builds an `NSCollectionLayoutGroup` that arranges its subitems vertically.
    ///
    /// - Returns: The built vertical `NSCollectionLayoutGroup`.
    /// - Note: This is an internal build SPI for the DSL. The framework calls it when converting to `NSCollectionLayout*`; do not call it directly.
    public final func _buildGroupLayout() -> NSCollectionLayoutGroup {
        let group = NSCollectionLayoutGroup.vertical(
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
