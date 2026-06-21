import UIKit

/// A protocol that `UICollectionReusableView` conforms to so it can be used with ``UIDynamicCollectionView``.
///
/// It abstracts supplementary views such as headers and footers, and is
/// configured through a ``Model`` that matches it one-to-one. It also conforms
/// to ``SelfIdentifiable``, so the type name is used as the reuse identifier.
public protocol UIReusableView: UICollectionReusableView, SelfIdentifiable {

    /// The model type used to configure this reusable view.
    associatedtype Model: UIReusableViewConfigurableModel

    /// The kind of supplementary element this view represents (element kind).
    ///
    /// For example: `UICollectionView.elementKindSectionHeader`,
    /// `UICollectionView.elementKindSectionFooter`.
    static var elementKind: String { get }

    /// Configures the view's content with the given model.
    ///
    /// - Parameters:
    ///   - model: The model holding the data to display in the view.
    ///   - indexPath: The index path where the view is located.
    func configure(model: Model, at indexPath: IndexPath)
}
