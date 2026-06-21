import UIKit

/// A wrapper that temporarily concretizes an abstracted ``UIReusableViewConfigurableModel`` inside ``UIDynamicCollectionView``.
///
/// It extracts and stores the supplementary view's identifier, element kind, and
/// concrete type all at once from an `any UIReusableViewConfigurableModel`. By
/// conforming to `Hashable`, it becomes easy to handle in a diffable data source,
/// playing a role similar to the relationship between the standard library's
/// `Hashable` protocol and `AnyHashable`.
///
/// - Important: This is an `internal` type used only within the library.
final internal class UIReusableViewConfigurator: Hashable {

    /// The identifier of the original model.
    var id: String

    /// The original model that was concretized.
    let base: any UIReusableViewConfigurableModel

    /// The reuse identifier of the matching supplementary view.
    let supplementaryViewIdentifier: String

    /// The element kind that the supplementary view represents.
    let elementKind: String

    /// The concrete type of the matching supplementary view.
    let supplementaryViewType: UICollectionReusableView.Type

    /// Creates the wrapper by extracting the view identifier/kind/type and the identifier from the concrete model type.
    ///
    /// - Parameter base: The ``UIReusableViewConfigurableModel`` model to concretize.
    init<Item: UIReusableViewConfigurableModel>(_ base: Item) {
        self.base = base
        self.supplementaryViewIdentifier = Item.UIReusableViewType.selfIdentifier
        self.elementKind = Item.UIReusableViewType.elementKind
        self.supplementaryViewType = Item.UIReusableViewType.self
        self.id = base.id
    }

    /// Two wrappers are considered equal if they have the same ``id``.
    static func == (lhs: UIReusableViewConfigurator, rhs: UIReusableViewConfigurator) -> Bool {
        lhs.id == rhs.id
    }

    /// Combines ``id`` into the hasher.
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
