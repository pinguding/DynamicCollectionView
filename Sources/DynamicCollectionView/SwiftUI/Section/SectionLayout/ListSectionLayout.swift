import SwiftUI

/// A type that specifies the appearance of a list section.
///
/// An alias for `UICollectionLayoutListConfiguration.Appearance`, it represents list styles
/// such as `.plain`, `.grouped`, and `.insetGrouped`.
public typealias ListSectionAppearance = UICollectionLayoutListConfiguration.Appearance

/// A ``SectionLayout`` that builds a list-style section layout based on `UICollectionLayoutListConfiguration`.
///
/// Along with the appearance (``ListSectionAppearance``), the header/footer are declared with ``ReusableLayout``.
/// The `contentInset(_:)` builder returns a copy with the inset applied.
///
/// ```swift
/// let layout = ListSectionLayout(
///     .insetGrouped,
///     header: { _, _ in ReusableItemLayout(kind: .header, height: .estimated(44)) }
/// )
/// .contentInset(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
/// ```
public struct ListSectionLayout: SectionLayout {

    private let appearance: ListSectionAppearance

    private let header: (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]?

    private let footer: (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]?

    private var contentInset: EdgeInsets = .init(.zero)

    /// Creates a list section layout from the appearance and header/footer closures.
    ///
    /// - Parameters:
    ///   - appearance: The list section's appearance.
    ///   - header: A closure that creates the section header reusable view. Defaults to no header (`nil`).
    ///   - footer: A closure that creates the section footer reusable view. Defaults to no footer (`nil`).
    public init(
        _ appearance: ListSectionAppearance,
        @ReusableViewLayoutBuilder header: @escaping (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]? = { _, _ in nil },
        @ReusableViewLayoutBuilder footer: @escaping (_ index: Int, _ environment: CollectionLayoutEnvironment) -> [any ReusableLayout]? = { _, _ in nil }
    ) {
        self.appearance = appearance
        self.header = header
        self.footer = footer
    }

    /// Returns a copy with the section content inset set.
    ///
    /// - Parameter inset: The section's edge insets.
    /// - Returns: A new ``ListSectionLayout`` with the inset applied.
    public func contentInset(_ inset: EdgeInsets) -> Self {
        var copiedSelf = self
        copiedSelf.contentInset = inset
        return copiedSelf
    }
}

extension ListSectionLayout {
    /// Builds an `NSCollectionLayoutSection` by combining the list configuration with the header/footer.
    ///
    /// It creates a list section whose header/footer modes are set to supplementary views (`.supplementary`).
    ///
    /// - Parameters:
    ///   - index: The index of the section being converted.
    ///   - environment: The environment used for layout calculation.
    /// - Returns: The built `NSCollectionLayoutSection`.
    /// - Note: This is an internal build SPI for the DSL. The framework calls it when converting to `NSCollectionLayout*`; do not call it directly.
    public func _buildSectionLayout(index: Int, environment: CollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var configuration = UICollectionLayoutListConfiguration(appearance: self.appearance)
        configuration.headerMode = .supplementary
        configuration.footerMode = .supplementary
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)

        var supplementaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []

        if let header = self.header(index, environment) {
            supplementaryItems.append(contentsOf: header.map { $0._buildSupplementaryLayout() })
        }
        if let footer = self.footer(index, environment) {
            supplementaryItems.append(contentsOf: footer.map { $0._buildSupplementaryLayout() })
        }

        section.contentInsets = .init(self.contentInset)
        section.boundarySupplementaryItems = supplementaryItems

        return section
    }
}
