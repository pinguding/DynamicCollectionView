import SwiftUI

/// A bridge view that hosts a SwiftUI ``ReusableView`` on top of a `UICollectionReusableView`.
///
/// Wraps the SwiftUI supplementary view given by the generic parameter `View` in a
/// `UIHostingController` and places it in the header/footer slot. It attaches the
/// hosting controller as a child of the parent view controller to manage its lifecycle,
/// and caches the size computed in ``preferredLayoutAttributesFitting(_:)`` per model
/// identifier to reduce repeated layout cost.
public final class SwiftUIReusableView<View: ReusableView>: UICollectionReusableView, UIReusableView {

    /// The data model type of the SwiftUI view this view hosts.
    public typealias Model = View.Model

    /// The element kind string of this supplementary view (header/footer).
    public static var elementKind: String {
        View.elementKind.rawValue
    }

    private var model: Model?

    private weak var hostingViewController: UIViewController?

    private var cachedSize: [String: CGSize] = [:]

    /// Detaches the hosting controller from its parent and cleans up references before the view is reused.
    override public func prepareForReuse() {
        super.prepareForReuse()

        self.detachParent(self.hostingViewController)
        self.hostingViewController = nil
        self.model = nil
    }

    /// Computes the layout attributes that fit the supplementary view and caches the size per model.
    ///
    /// If a previously computed size for the same model is already in the cache, it
    /// reuses that value; otherwise it computes the size via the superclass implementation
    /// and caches it keyed by the model identifier (`model.id`).
    ///
    /// - Parameter layoutAttributes: The layout attributes proposed by the collection view.
    /// - Returns: The layout attributes with the content size applied.
    override public func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {

        guard let model else {
            return super.preferredLayoutAttributesFitting(layoutAttributes)
        }

        if let cachedSize =  self.cachedSize[model.id] {
            layoutAttributes.size = cachedSize
            return layoutAttributes
        } else {
            let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
            let size = attributes.size
            layoutAttributes.size = size
            self.cachedSize[model.id] = size
            return attributes
        }
    }

    /// Creates a SwiftUI supplementary view from the given model and hosts it.
    ///
    /// Builds a ``ReusableView`` from the model and index path, wraps it in a
    /// `UIHostingController`, pins it to the four edges of the view to fill it, and
    /// attaches the hosting controller as a child of the parent view controller.
    ///
    /// - Parameters:
    ///   - model: The data model the view displays.
    ///   - indexPath: The index path where this view is located.
    public func configure(model: Model, at indexPath: IndexPath) {
        self.model = model
        let cellView = View.init(model: model, indexPath: indexPath)
        let hostingViewController = UIHostingController(rootView: cellView)
        guard let hostingCellView = hostingViewController.view else {
            return
        }
        self.hostingViewController = hostingViewController
        hostingCellView.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(hostingCellView)

        self.attachParent(self.parentViewController(), childViewController: hostingViewController)

        NSLayoutConstraint.activate([
            hostingCellView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingCellView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            hostingCellView.topAnchor.constraint(equalTo: self.topAnchor),
            hostingCellView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    /// Attaches the hosting controller as a child of the parent view controller.
    ///
    /// - Parameters:
    ///   - parentViewController: The parent view controller to add the child to. Does nothing if `nil`.
    ///   - childViewController: The hosting controller to attach to the parent.
    private func attachParent(_ parentViewController: UIViewController?, childViewController: UIViewController) {
        guard let parentViewController else { return }
        parentViewController.addChild(childViewController)
        childViewController.didMove(toParent: parentViewController)
    }

    /// Detaches the hosting controller from its parent and cleans up its view and constraints.
    ///
    /// - Parameter childViewController: The hosting controller to detach.
    private func detachParent(_ childViewController: UIViewController?) {
        childViewController?.removeFromParent()
        childViewController?.view.removeConstraints(childViewController?.view.constraints ?? [])
        childViewController?.view.removeFromSuperview()
    }

    /// Walks up the responder chain to find the nearest view controller that contains this view.
    ///
    /// - Returns: The view controller found, or `nil` if none.
    private func parentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let currentResponder = responder {
            if let viewController = currentResponder as? UIViewController {
                return viewController
            }
            responder = currentResponder.next
        }
        return nil
    }
}
