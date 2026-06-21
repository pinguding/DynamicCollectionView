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

    /// Cleans up the hosted SwiftUI view and the model reference before the cell is reused.
    override public func prepareForReuse() {
        super.prepareForReuse()

        self.contentView.subviews.forEach { $0.removeFromSuperview() }
        self.model = nil
    }

    /// Creates a SwiftUI cell view from the given model and hosts it in the cell.
    ///
    /// Builds a ``CellView`` from the model and index path, wraps it in a
    /// `UIHostingController`, and pins it to the four edges of `contentView` to fill it.
    ///
    /// - Parameters:
    ///   - model: The data model the cell displays.
    ///   - indexPath: The index path where this cell is located.
    public func configure(model: Model, at indexPath: IndexPath) {
        self.model = model
        let cellView = View.init(model: model, indexPath: indexPath)
        let hostingViewController = UIHostingController(rootView: cellView)
        guard let hostingCellView = hostingViewController.view else {
            return
        }
        hostingCellView.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(hostingCellView)

        NSLayoutConstraint.activate([
            hostingCellView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            hostingCellView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            hostingCellView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            hostingCellView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }
}
