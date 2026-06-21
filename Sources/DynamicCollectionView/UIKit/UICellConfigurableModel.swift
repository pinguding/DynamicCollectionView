import UIKit

/// The model protocol used to dequeue and configure a ``UICell`` in ``UIDynamicCollectionView``.
///
/// It links a model and a cell one-to-one through the associated type ``CellType``.
/// Being class-based (`AnyObject`), it has reference semantics and serves as the
/// entry point through which ``UIDynamicCollectionView`` produces an appropriate
/// cell from a model.
///
/// - Note: This protocol is intentionally not isolated to `@MainActor`.
///   This allows a Reactor/ViewModel to assemble sections and models on a
///   background thread, and thread safety is ensured through the flow of
///   "assemble in the background → hand off to main → apply on main".
public protocol UICellConfigurableModel: AnyObject {

    /// The cell type that matches this model.
    associatedtype CellType: UICell

    /// The value used as the item identifier in `UICollectionViewDiffableDataSource`.
    var id: String { get }

    /// Casts the dequeued cell to ``CellType``, configures it with this model, and returns it.
    ///
    /// - Parameters:
    ///   - dequeuedCell: The cell dequeued from the collection view.
    ///   - indexPath: The index path where the cell is located.
    /// - Returns: The successfully configured ``CellType`` cell, or `nil` if the cast fails.
    func configuredCell(_ dequeuedCell: UICollectionViewCell, at indexPath: IndexPath) -> CellType?
}

public extension UICellConfigurableModel {

    /// The default implementation that casts the dequeued cell and itself to
    /// ``CellType`` and its model type respectively, then calls
    /// `configure(model:at:)` to configure the cell.
    ///
    /// - Parameters:
    ///   - dequeuedCell: The cell dequeued from the collection view.
    ///   - indexPath: The index path where the cell is located.
    /// - Returns: The configured cell, or `nil` if casting the cell or the model fails.
    func configuredCell(_ dequeuedCell: UICollectionViewCell, at indexPath: IndexPath) -> CellType? {
        guard let cell = dequeuedCell as? CellType,
              let transformedModel = self as? Self.CellType.Model
        else { return nil }

        cell.configure(model: transformedModel, at: indexPath)

        return cell
    }
}
