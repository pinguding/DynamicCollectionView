import Foundation

/// A data model protocol for configuring SwiftUI-based cells (``CellView``).
///
/// By inheriting from `UICellConfigurableModel`, it declares via associated types
/// which SwiftUI cell view the model maps to and which `UICollectionViewCell` type
/// hosts that cell.
///
/// - Note: This protocol does not require conformance to `ObservableObject`. Only when
///   you need to observe value changes inside the cell should the model type adopt
///   `ObservableObject` directly.
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
