import UIKit

/// A protocol that `UICollectionViewCell` conforms to so it can be used with ``UIDynamicCollectionView``.
///
/// A cell conforming to this protocol is configured through a ``Model`` that
/// matches it one-to-one. It also conforms to ``SelfIdentifiable``, so the type
/// name is used as the reuse identifier without specifying a separate one.
///
/// ```swift
/// final class ProductCell: UICollectionViewCell, UICell {
///     func configure(model: ProductCellModel, at indexPath: IndexPath) {
///         // Configure the cell's UI from the model.
///     }
/// }
/// ```
public protocol UICell: UICollectionViewCell, SelfIdentifiable {

    /// The model type used to configure this cell.
    associatedtype Model: UICellConfigurableModel

    /// Configures the cell's content with the given model.
    ///
    /// - Parameters:
    ///   - model: The model holding the data to display in the cell.
    ///   - indexPath: The index path where the cell is located.
    func configure(model: Model, at indexPath: IndexPath)
}
