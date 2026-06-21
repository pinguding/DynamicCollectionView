import UIKit

/// An item layout that defines the layout of a header or footer reusable view.
///
/// It takes a ``ReusableViewElementKind`` and a height to create an
/// `NSCollectionLayoutBoundarySupplementaryItem`. The width always fills the container.
public class ReusableItemLayout {

    private let height: LayoutSize

    private let kind: ReusableViewElementKind

    /// Creates a reusable view layout with the given kind and height.
    ///
    /// - Parameters:
    ///   - kind: The reusable view kind (`.header` or `.footer`).
    ///   - height: The reusable view's height dimension.
    public init(kind: ReusableViewElementKind, height: LayoutSize) {
        self.height = height
        self.kind = kind
    }
}

extension ReusableItemLayout: ReusableLayout {

    /// Builds the boundary supplementary item according to the kind and height.
    ///
    /// A header is aligned to the top (`.top`), and a footer to the bottom (`.bottom`).
    ///
    /// - Returns: The built `NSCollectionLayoutBoundarySupplementaryItem`.
    /// - Note: This is an internal build SPI for the DSL. The framework calls it when converting to `NSCollectionLayout*`; do not call it directly.
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
