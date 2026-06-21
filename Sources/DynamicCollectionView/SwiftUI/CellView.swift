import SwiftUI

/// A protocol adopted by SwiftUI views that are rendered as cells in the collection view.
///
/// A SwiftUI `View` that adopts this protocol is hosted on top of a
/// `UICollectionViewCell` through the ``SwiftUICell`` bridge. The associated type
/// ``Model`` declares the type of data the cell displays, and an initializer that
/// receives the model and index path builds the cell's content.
public protocol CellView: View {
    /// The type of the data model this cell view displays.
    ///
    /// It must be a type that adopts ``CellViewConfigurableModel``, and it serves to
    /// connect the cell and the model to each other.
    associatedtype Model: CellViewConfigurableModel

    /// Creates a cell view from the given model and index path.
    ///
    /// - Parameters:
    ///   - model: The data model the cell displays.
    ///   - indexPath: The collection view index path where this cell is located.
    init(model: Model, indexPath: IndexPath)
}
