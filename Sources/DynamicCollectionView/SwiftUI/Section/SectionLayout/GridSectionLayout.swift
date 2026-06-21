import SwiftUI

/// An enumeration that defines a section's orthogonal (horizontal) scrolling behavior.
///
/// It maps to `UICollectionLayoutSectionOrthogonalScrollingBehavior` and is passed to
/// ``GridSectionLayout/orthogonalScrollingBehavior(_:)``.
public enum OrthogonalScrollingBehavior {
    /// Disables orthogonal scrolling.
    case none
    /// Scrolls freely and continuously.
    case continuous
    /// Scrolls continuously but snaps to the leading boundary of a group.
    case continuousGroupLeadingBoundary
    /// Pages by container.
    case paging
    /// Pages by group.
    case groupPaging
    /// Pages by group with center alignment.
    case groupPagingCentered

    /// The value converted to the corresponding `UICollectionLayoutSectionOrthogonalScrollingBehavior`.
    var uiCollectionLayoutSectionOrthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior {
        switch self {
        case .none:
            return .none
        case .continuous:
            return .continuous
        case .continuousGroupLeadingBoundary:
            return .continuousGroupLeadingBoundary
        case .paging:
            return .paging
        case .groupPaging:
            return .groupPaging
        case .groupPagingCentered:
            return .groupPagingCentered
        }
    }
}

/// A ``SectionLayout`` that builds a grid-style section layout from header/body/footer closures.
///
/// The body group is declared with ``GroupLayout``, and the header/footer with ``ReusableLayout``.
/// The `interGroupSpacing(_:)`, `contentInsets(_:)`, `orthogonalScrollingBehavior(_:)`,
/// and `visibleItem(_:)` builders each return a copy with the change applied.
///
/// ```swift
/// let layout = GridSectionLayout(
///     header: { _, _ in ReusableItemLayout(kind: .header, height: .absolute(44)) },
///     body: { _, _ in
///         HGroupLayout(width: .fractionalWidth(1.0), height: .absolute(120)) {
///             GridItemLayout(width: .fractionalWidth(0.5), height: .fractionalHeight(1.0))
///         }
///     }
/// )
/// .interGroupSpacing(8)
/// .orthogonalScrollingBehavior(.groupPaging)
/// ```
public struct GridSectionLayout {

    private let header: (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]?

    private let body: (_ index: Int, _ environment: CollectionLayoutEnvironment) -> any GroupLayout

    private let footer: (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]?

    private var interGroupSpacing: CGFloat = 0

    private var contentInsets: EdgeInsets = .init(.zero)

    private var orthogonalScrollingBehavior: OrthogonalScrollingBehavior = .none

    private var visibleItemsInvalidationHandler: (([any CollectionVisibleItem], CGPoint, any CollectionLayoutEnvironment) -> Void)? = nil

    /// Creates a grid section layout from header/body/footer closures.
    ///
    /// - Parameters:
    ///   - header: A closure that creates the section header reusable view. Defaults to no header (`nil`).
    ///   - body: A closure that creates the section body group.
    ///   - footer: A closure that creates the section footer reusable view. Defaults to no footer (`nil`).
    public init(
        @ReusableViewLayoutBuilder header: @escaping (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]? = { _, _ in nil },
        body: @escaping (_ index: Int, _ environment: CollectionLayoutEnvironment) -> any GroupLayout,
        @ReusableViewLayoutBuilder footer: @escaping (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]? = { _, _ in nil }
    ) {
        self.header = header
        self.body = body
        self.footer = footer
    }

    /// Returns a copy with the inter-group spacing set.
    ///
    /// - Parameter spacing: The spacing between groups, in points.
    /// - Returns: A new ``GridSectionLayout`` with the spacing applied.
    public func interGroupSpacing(_ spacing: CGFloat) -> Self {
        var copiedSelf = self
        copiedSelf.interGroupSpacing = spacing
        return copiedSelf
    }

    /// Returns a copy with the section content insets set.
    ///
    /// - Parameter insets: The section's edge insets.
    /// - Returns: A new ``GridSectionLayout`` with the insets applied.
    public func contentInsets(_ insets: EdgeInsets) -> Self {
        var copiedSelf = self
        copiedSelf.contentInsets = insets
        return copiedSelf
    }

    /// Returns a copy with the orthogonal scrolling behavior set.
    ///
    /// - Parameter behavior: The ``OrthogonalScrollingBehavior`` to apply.
    /// - Returns: A new ``GridSectionLayout`` with the scrolling behavior applied.
    public func orthogonalScrollingBehavior(_ behavior: OrthogonalScrollingBehavior) -> Self {
        var copiedSelf = self
        copiedSelf.orthogonalScrollingBehavior = behavior
        return copiedSelf
    }

    /// Returns a copy with the visible items invalidation handler set.
    ///
    /// Use this to track or transform (e.g. parallax effects) the items that become visible during scrolling.
    ///
    /// - Parameter handler: A handler that receives the list of visible items, the offset, and the environment.
    /// - Returns: A new ``GridSectionLayout`` with the handler applied.
    public func visibleItem(_ handler: @escaping ([any CollectionVisibleItem], CGPoint, any CollectionLayoutEnvironment) -> Void) -> Self {
        var copiedSelf = self
        copiedSelf.visibleItemsInvalidationHandler = handler
        return copiedSelf
    }
}

extension GridSectionLayout: SectionLayout {
    /// Builds an `NSCollectionLayoutSection` by combining the header/body/footer with the configured values.
    ///
    /// - Parameters:
    ///   - index: The index of the section being converted.
    ///   - environment: The environment used for layout calculation.
    /// - Returns: The built `NSCollectionLayoutSection`.
    /// - Note: This is an internal build SPI for the DSL. The framework calls it when converting to `NSCollectionLayout*`; do not call it directly.
    public func _buildSectionLayout(index: Int, environment: CollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let group = self.body(index, environment)._buildGroupLayout()

        var supplementaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []

        if let header = self.header(index, environment) {
            supplementaryItems.append(contentsOf: header.map { $0._buildSupplementaryLayout() })
        }
        if let footer = self.footer(index, environment) {
            supplementaryItems.append(contentsOf: footer.map { $0._buildSupplementaryLayout() })
        }

        let section = NSCollectionLayoutSection(group: group)

        section.boundarySupplementaryItems = supplementaryItems

        section.interGroupSpacing = self.interGroupSpacing
        section.contentInsets = .init(self.contentInsets)
        section.orthogonalScrollingBehavior = self.orthogonalScrollingBehavior.uiCollectionLayoutSectionOrthogonalScrollingBehavior
        section.visibleItemsInvalidationHandler = self.visibleItemsInvalidationHandler

        return section
    }
}
