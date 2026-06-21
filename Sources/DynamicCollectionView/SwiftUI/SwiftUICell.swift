import SwiftUI

/// A bridge cell that hosts a SwiftUI ``CellView`` on top of a `UICollectionViewCell`.
///
/// Wraps the SwiftUI cell view given by the generic parameter `View` in a
/// `UIHostingController`, then lays it out to fill the cell's `contentView` using Auto
/// Layout. It connects the UIKit collection view infrastructure with declarative SwiftUI views.
public final class SwiftUICell<View: CellView>: UICollectionViewCell, UICell {

    /// The data model type of the SwiftUI view this cell hosts.
    public typealias Model = View.Model

    private var model: Model?

    /// The hosting controller that renders the SwiftUI cell view.
    ///
    /// A fresh controller is created on every ``configure(model:at:)`` call so the
    /// hosted ``CellView``'s internal `@State` always starts from its initial value.
    /// Reusing a single controller across cell reuse would keep the SwiftUI view
    /// identity stable and leak the previous item's `@State` into the next item.
    /// It is retained in a property (rather than a local variable) only so the
    /// controller is not deallocated while its view stays in the hierarchy.
    private var hostingController: UIHostingController<View>?

    /// Tears down the hosted SwiftUI view and clears the model before the cell is reused.
    override public func prepareForReuse() {
        super.prepareForReuse()

        self.hostingController?.view.removeFromSuperview()
        self.hostingController = nil
        self.model = nil
    }

    /// Creates a SwiftUI cell view from the given model and hosts it in the cell.
    ///
    /// Builds a ``CellView`` from the model and index path, wraps it in a brand-new
    /// `UIHostingController`, and pins it to the four edges of `contentView` to fill it.
    /// Any previously hosted controller is discarded first so each configuration starts
    /// with fresh SwiftUI state.
    ///
    /// - Parameters:
    ///   - model: The data model the cell displays.
    ///   - indexPath: The index path where this cell is located.
    public func configure(model: Model, at indexPath: IndexPath) {
        self.model = model

        self.hostingController?.view.removeFromSuperview()

        let cellView = View.init(model: model, indexPath: indexPath)
        let hostingViewController = UIHostingController(rootView: cellView)
        self.hostingController = hostingViewController

        guard let hostingCellView = hostingViewController.view else {
            return
        }
        hostingCellView.translatesAutoresizingMaskIntoConstraints = false
        hostingCellView.backgroundColor = .clear

        self.contentView.addSubview(hostingCellView)

        NSLayoutConstraint.activate([
            hostingCellView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            hostingCellView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            hostingCellView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            hostingCellView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }
}
