import SwiftUI

/// An enum representing the kind of supplementary view (header/footer).
///
/// Each case maps to a UIKit supplementary element kind string
/// (`UICollectionView.elementKindSectionHeader` / `Footer`).
public enum ReusableViewElementKind: String {
    /// A section header supplementary view.
    case header
    /// A section footer supplementary view.
    case footer

    /// The UIKit supplementary element kind string corresponding to the case.
    public var rawValue: String {
        switch self {
        case .header:
            return UICollectionView.elementKindSectionHeader
        case .footer:
            return UICollectionView.elementKindSectionFooter
        }
    }
}

/// A protocol adopted by SwiftUI views that are rendered as supplementary views (header/footer) in the collection view.
///
/// Similar to ``CellView``, a SwiftUI `View` that adopts this protocol is hosted on top
/// of a `UICollectionReusableView` through the ``SwiftUIReusableView`` bridge. The
/// associated type ``Model`` and ``elementKind`` declare which data to display at which
/// position (header/footer).
///
/// - Important: Like ``CellView``, a ``ReusableView`` is hosted inside a **reused**
///   `UICollectionReusableView` whose host is recreated on every reuse. **Do not store mutable
///   UI state in the view with `@State` or `@Binding`** — it is reset on reuse. Keep the
///   supplementary view a stateless function of its ``Model``, and when state must persist make
///   the model an `ObservableObject` (`@Published` properties) and observe it with
///   `@ObservedObject`. The model is the single source of truth. See ``CellView`` for the full
///   rationale and example.
public protocol ReusableView: View {

    /// The type of the data model this supplementary view displays.
    associatedtype Model: ReusableViewConfigurableModel

    /// The supplementary element kind indicating whether this view is a header or a footer.
    static var elementKind: ReusableViewElementKind { get }

    /// Creates a supplementary view from the given model and index path.
    ///
    /// - Parameters:
    ///   - model: The data model the view displays.
    ///   - indexPath: The collection view index path where this view is located.
    init(model: Model, indexPath: IndexPath)
}
