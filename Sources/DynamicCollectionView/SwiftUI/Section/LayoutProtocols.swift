import SwiftUI

/// A protocol that defines a section-level layout.
///
/// Adopted by ``GridSectionLayout`` and ``ListSectionLayout``, it sits at the top (section level)
/// of the layout DSL hierarchy.
public protocol SectionLayout {
    /// Converts the section layout into an `NSCollectionLayoutSection`.
    ///
    /// - Parameters:
    ///   - index: The index of the section being converted.
    ///   - environment: The environment used for layout calculation.
    /// - Returns: The built `NSCollectionLayoutSection`.
    /// - Note: This is an internal build SPI for the DSL. The framework calls it when converting to `NSCollectionLayout*`; do not call it directly.
    func _buildSectionLayout(index: Int, environment: CollectionLayoutEnvironment) -> NSCollectionLayoutSection
}

/// A protocol that defines a group-level layout.
///
/// It inherits from ``ItemLayout`` and is adopted by ``HGroupLayout``, ``VGroupLayout``, and ``WaterFallGroupLayout``.
public protocol GroupLayout: ItemLayout {
    /// Converts the group layout into an `NSCollectionLayoutGroup`.
    ///
    /// - Returns: The built `NSCollectionLayoutGroup`.
    /// - Note: This is an internal build SPI for the DSL. The framework calls it when converting to `NSCollectionLayout*`; do not call it directly.
    func _buildGroupLayout() -> NSCollectionLayoutGroup
}

public extension GroupLayout {
    /// The default implementation that satisfies the ``ItemLayout/_buildItemLayout()`` requirement via the group build.
    ///
    /// - Returns: The group upcast to an `NSCollectionLayoutItem`.
    /// - Note: This is an internal build SPI for the DSL. Do not call it directly.
    func _buildItemLayout() -> NSCollectionLayoutItem {
        self._buildGroupLayout() as NSCollectionLayoutItem
    }
}

/// A protocol that defines a reusable view (header/footer) layout.
///
/// It inherits from ``ItemLayout`` and is adopted by ``ReusableItemLayout``.
public protocol ReusableLayout: ItemLayout {
    /// Converts the reusable view layout into an `NSCollectionLayoutBoundarySupplementaryItem`.
    ///
    /// - Returns: The built boundary supplementary item.
    /// - Note: This is an internal build SPI for the DSL. The framework calls it when converting to `NSCollectionLayout*`; do not call it directly.
    func _buildSupplementaryLayout() -> NSCollectionLayoutBoundarySupplementaryItem
}

public extension ReusableLayout {

    /// The default implementation that satisfies the ``ItemLayout/_buildItemLayout()`` requirement via the supplementary item build.
    ///
    /// - Returns: The supplementary item upcast to an `NSCollectionLayoutItem`.
    /// - Note: This is an internal build SPI for the DSL. Do not call it directly.
    func _buildItemLayout() -> NSCollectionLayoutItem {
        self._buildSupplementaryLayout() as NSCollectionLayoutItem
    }
}

/// A protocol that defines an item-level layout.
///
/// As the base unit of the layout DSL hierarchy, it is adopted by ``GridItemLayout`` and
/// is the parent protocol of ``GroupLayout`` and ``ReusableLayout``.
public protocol ItemLayout {
    /// Converts the item layout into an `NSCollectionLayoutItem`.
    ///
    /// - Returns: The built `NSCollectionLayoutItem`.
    /// - Note: This is an internal build SPI for the DSL. The framework calls it when converting to `NSCollectionLayout*`; do not call it directly.
    func _buildItemLayout() -> NSCollectionLayoutItem
}

/// A protocol that defines a custom variable-height item layout.
///
/// Adopted by layouts that compute frames directly, such as a waterfall.
public protocol CustomItemLayout {
    /// Converts the custom item layout into an `NSCollectionLayoutGroupCustomItem`.
    ///
    /// - Returns: The built custom group item.
    /// - Note: This is an internal build SPI for the DSL. The framework calls it when converting to `NSCollectionLayout*`; do not call it directly.
    func _buildCustomItemLayout() -> NSCollectionLayoutGroupCustomItem
}
