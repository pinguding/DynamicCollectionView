import UIKit

/// An item layout that defines the size of a single cell.
///
/// It takes a width and height as ``LayoutSize`` values and creates one `NSCollectionLayoutItem`.
/// Typically used as a subitem of ``HGroupLayout`` or ``VGroupLayout``.
public class GridItemLayout {

    private let width: LayoutSize

    private let height: LayoutSize

    /// Creates an item layout with the given width and height.
    ///
    /// - Parameters:
    ///   - width: The item's width dimension.
    ///   - height: The item's height dimension.
    public init(width: LayoutSize, height: LayoutSize) {
        self.width = width
        self.height = height
    }
}

extension GridItemLayout: ItemLayout {

    /// Builds an `NSCollectionLayoutItem` with the specified width and height.
    ///
    /// - Returns: The built `NSCollectionLayoutItem`.
    /// - Note: This is an internal build SPI for the DSL. The framework calls it when converting to `NSCollectionLayout*`; do not call it directly.
    public final func _buildItemLayout() -> NSCollectionLayoutItem {
        .init(layoutSize: .init(
            widthDimension: self.width.nsCollectionLayoutDimension,
            heightDimension: self.height.nsCollectionLayoutDimension
        ))
    }
}
