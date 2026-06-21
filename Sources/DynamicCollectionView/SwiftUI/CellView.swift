import SwiftUI

/// A protocol adopted by SwiftUI views that are rendered as cells in the collection view.
///
/// A SwiftUI `View` that adopts this protocol is hosted on top of a
/// `UICollectionViewCell` through the ``SwiftUICell`` bridge. The associated type
/// ``Model`` declares the type of data the cell displays, and an initializer that
/// receives the model and index path builds the cell's content.
///
/// - Important: A ``CellView`` is hosted inside a **reused** `UICollectionViewCell`, and the
///   host is recreated on every reuse. Therefore **do not store mutable UI state in the view
///   with `@State` or `@Binding`** — such state is reset when the cell is reused (and, if the
///   host were instead kept alive, it would bleed between unrelated items). Treat a cell view
///   as a stateless function of its ``Model``.
///
///   When a cell needs mutable state that must persist (selection, like, expand/collapse, …),
///   put that state on the ``Model`` instead and keep the **model as the single source of
///   truth**: make the model an `ObservableObject`, declare the state with `@Published`, and
///   hold it in the view with `@ObservedObject`. Because the model outlives cell reuse and stays
///   bound to its item, the state survives reuse and never leaks to the wrong cell.
///
/// ```swift
/// final class ProductCellModel: CellViewConfigurableModel, ObservableObject {
///     let id: String
///     @Published var isLiked = false
///     // ...
/// }
///
/// struct ProductCell: CellView {
///     // Source of truth is the model — not @State / @Binding.
///     @ObservedObject private var model: ProductCellModel
///
///     init(model: ProductCellModel, indexPath: IndexPath) {
///         self.model = model
///     }
///
///     var body: some View {
///         Button { model.isLiked.toggle() } label: {
///             Image(systemName: model.isLiked ? "heart.fill" : "heart")
///         }
///     }
/// }
/// ```
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
