import UIKit

/// A wrapper that temporarily concretizes an abstracted ``UICellConfigurableModel`` inside ``UIDynamicCollectionView``.
///
/// It extracts and stores concrete information such as the cell identifier and
/// cell type all at once from an `any UICellConfigurableModel` that has lost its
/// generic context. By conforming to `Hashable`, it becomes easy to handle in a
/// diffable data source (snapshot), playing a role similar to the relationship
/// between the standard library's `Hashable` protocol and `AnyHashable`.
///
/// - Important: This is an `internal` type used only within the library.
final internal class UICellConfigurator: Hashable {

    /// The identifier of the original model.
    let id: String

    /// The original model that was concretized.
    let base: any UICellConfigurableModel

    /// The reuse identifier of the matching cell.
    let cellIdentifier: String

    /// The concrete type of the matching cell.
    let cellType: UICollectionViewCell.Type

    /// Creates the wrapper by extracting the cell identifier/type and the identifier from the concrete model type.
    ///
    /// - Parameter base: The ``UICellConfigurableModel`` model to concretize.
    init<Model: UICellConfigurableModel>(_ base: Model) {
        self.base = base
        self.cellIdentifier = Model.CellType.selfIdentifier
        self.cellType = Model.CellType.self
        self.id = base.id
    }

    /// Two wrappers are considered equal if they have the same ``id``.
    static func == (lhs: UICellConfigurator, rhs: UICellConfigurator) -> Bool {
        lhs.id == rhs.id
    }

    /// Combines ``id`` into the hasher.
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
