import Foundation

/// A data model protocol for configuring SwiftUI-based cells (``CellView``).
///
/// By inheriting from `UICellConfigurableModel`, it declares via associated types
/// which SwiftUI cell view the model maps to and which `UICollectionViewCell` type
/// hosts that cell.
///
/// - Note: This protocol does not require conformance to `ObservableObject`. A model that only
///   feeds immutable data into its cell can stay a plain `final class`.
///
/// - Important: The model is the **single source of truth** for its cell. A ``CellView`` is
///   hosted in a reused cell and must not keep mutable state in `@State`/`@Binding` (see
///   ``CellView`` for why). When a cell needs state that mutates and must persist across reuse,
///   define that state here on the model: adopt `ObservableObject`, mark the properties
///   `@Published`, and observe the model from the cell with `@ObservedObject`.
public protocol CellViewConfigurableModel: UICellConfigurableModel {

    /// The type of the SwiftUI cell view configured by this model.
    associatedtype CellViewType: CellView

    /// The `UICollectionViewCell` type that hosts the model.
    ///
    /// The default is ``SwiftUICell``, which wraps ``CellViewType`` in a
    /// `UIHostingController`.
    associatedtype CellType = SwiftUICell<CellViewType>
}

/// A ``CellViewConfigurableModel`` that lets you specify the size ratio the cell occupies directly.
///
/// Adopt this when you want to control the width/height ratio from the model instead of the standard layout.
public protocol CustomLayoutCellViewConfigurableModel: CellViewConfigurableModel {

    /// The size ratio the cell occupies in the layout.
    var sizeRatio: CGFloat { get }
}
