import UIKit

/// The model protocol used to dequeue and configure a ``UIReusableView`` in ``UIDynamicCollectionView``.
///
/// It links a model and a supplementary view one-to-one through the associated
/// type ``UIReusableViewType``. It is responsible for the data representation of
/// supplementary elements such as headers and footers.
///
/// - Note: This protocol is intentionally not isolated to `@MainActor`.
///   This allows a Reactor/ViewModel to assemble sections and models on a
///   background thread, and thread safety is ensured through the flow of
///   "assemble in the background → hand off to main → apply on main".
public protocol UIReusableViewConfigurableModel: AnyObject {

    /// The reusable view type that matches this model.
    associatedtype UIReusableViewType: UIReusableView

    /// The value that identifies this model.
    var id: String { get }

    /// Casts the dequeued supplementary view to ``UIReusableViewType``, configures it with this model, and returns it.
    ///
    /// - Parameters:
    ///   - dequeuedSupplementaryView: The supplementary view dequeued from the collection view.
    ///   - indexPath: The index path where the view is located.
    /// - Returns: The successfully configured ``UIReusableViewType`` view, or `nil` if the cast fails.
    func configuredSupplementaryView(_ dequeuedSupplementaryView: UICollectionReusableView, indexPath: IndexPath) -> UIReusableViewType?
}

public extension UIReusableViewConfigurableModel {

    /// The default implementation that casts the dequeued supplementary view and
    /// itself to ``UIReusableViewType`` and its model type respectively, then
    /// calls `configure(model:at:)` to configure the view.
    ///
    /// - Parameters:
    ///   - dequeuedSupplementaryView: The supplementary view dequeued from the collection view.
    ///   - indexPath: The index path where the view is located.
    /// - Returns: The configured view, or `nil` if casting the view or the model fails.
    func configuredSupplementaryView(_ dequeuedSupplementaryView: UICollectionReusableView, indexPath: IndexPath)
    -> UIReusableViewType? {
        guard let supplementaryView = dequeuedSupplementaryView as? UIReusableViewType,
              let transformedModel = self as? UIReusableViewType.Model
        else { return nil }

        supplementaryView.configure(model: transformedModel, at: indexPath)
        return supplementaryView
    }
}
