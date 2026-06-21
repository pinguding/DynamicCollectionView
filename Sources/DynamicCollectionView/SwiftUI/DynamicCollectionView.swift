import SwiftUI

/// A declarative SwiftUI wrapper around `UICollectionView`.
///
/// Takes an array of sections and renders a compositional-layout-based collection
/// view. Internally it uses `UICollectionViewDiffableDataSource`, so when the parent
/// view's state changes and a new array of sections is passed in, it computes the
/// difference from the previous snapshot and automatically animates the insertion,
/// deletion, and movement of items.
///
/// Events such as selection and display are registered with chaining modifiers like
/// ``didSelectItem(_:)``, ``willDisplayItem(_:)``, and
/// ``willDisplayReusableItem(_:)``. These handlers are stored as struct values and
/// re-injected into `context.coordinator` on every update in
/// ``updateUIView(_:context:)``, so the latest closure is always called even when the
/// state changes.
///
/// ```swift
/// struct ContentView: View {
///     @State private var sections: [any SectionContext] = ...
///
///     var body: some View {
///         DynamicCollectionView(sections)
///             .didSelectItem { item, indexPath in
///                 print("Selected: \(indexPath)")
///             }
///             .willDisplayItem { item, indexPath in
///                 // Pagination, etc.
///             }
///             .keyboardDismissMode(.onDrag)
///     }
/// }
/// ```
///
/// - Note: Sections are wrapped in ``SwiftUISection`` internally before being passed to `UIDynamicCollectionView.apply`.
public struct DynamicCollectionView: UIViewRepresentable {

    /// The UIKit view type that `UIViewRepresentable` creates and manages.
    public typealias UIViewType = UIDynamicCollectionView

    /// The coordinator type that relays the collection view's delegate events.
    public typealias Coordinator = Self.DynamicCollectionViewCoordinator

    private let sections: [any SectionContext]

    private let animatingDifferences: Bool

    private var itemDisplayHandler: ((_ item: any UICellConfigurableModel, _ indexPath: IndexPath) -> Void)?

    private var reusableItemDisplayHandler: ((_ item: any UIReusableViewConfigurableModel, _ indexPath: IndexPath) -> Void)?

    private var didSelectItemHandler: ((_ item: any UICellConfigurableModel, _ indexPath: IndexPath) -> Void)?

    private var keyboardDismissModeValue: UIScrollView.KeyboardDismissMode?

    /// Creates a collection view from an array of sections to display.
    ///
    /// When the parent state updates and a new `sections` is passed to the same
    /// collection view, the diffable data source computes the difference from the
    /// previous snapshot and reflects the changes.
    ///
    /// - Parameters:
    ///   - sections: The list of sections to display in the collection view.
    ///   - animatingDifferences: Whether to animate changes when applying the snapshot. Defaults to `true`.
    public init(_ sections: [any SectionContext], animatingDifferences: Bool = true) {
        self.sections = sections
        self.animatingDifferences = animatingDifferences
    }

    /// Creates a collection view from a binding to an array of sections.
    ///
    /// Behaves identically to the value-based ``init(_:animatingDifferences:)``, and is
    /// used when the call site wants to pass `@State` or similar with `$`. It reads the
    /// binding's current value and applies it on every update, so changes to the bound
    /// state are reflected directly.
    ///
    /// ```swift
    /// @State private var sections: [any SectionContext] = ...
    /// DynamicCollectionView($sections)
    /// ```
    ///
    /// - Parameters:
    ///   - sections: A binding to the list of sections to display in the collection view.
    ///   - animatingDifferences: Whether to animate changes when applying the snapshot. Defaults to `true`.
    public init(_ sections: Binding<[any SectionContext]>, animatingDifferences: Bool = true) {
        self.sections = sections.wrappedValue
        self.animatingDifferences = animatingDifferences
    }

    /// Creates the ``DynamicCollectionViewCoordinator`` that handles delegate events.
    ///
    /// - Returns: A newly created coordinator instance.
    public func makeCoordinator() -> DynamicCollectionViewCoordinator {
        DynamicCollectionViewCoordinator()
    }

    /// Creates the underlying ``UIDynamicCollectionView`` and connects the coordinator as its delegate.
    ///
    /// - Parameter context: The representation context SwiftUI provides, including the coordinator.
    /// - Returns: A newly created UIKit collection view.
    public func makeUIView(context: Context) -> UIDynamicCollectionView {
        let collectionView = UIDynamicCollectionView()
        collectionView.delegate = context.coordinator
        return collectionView
    }

    /// Injects the latest handlers and settings into the coordinator and applies the current section snapshot.
    ///
    /// Re-injects the closures stored by the modifiers into the coordinator on every
    /// update to avoid the stale-closure problem, then wraps the sections in
    /// ``SwiftUISection`` and applies them to the collection view.
    ///
    /// - Parameters:
    ///   - uiView: The UIKit collection view to update.
    ///   - context: The representation context, including the coordinator.
    public func updateUIView(_ uiView: UIDynamicCollectionView, context: Context) {
        context.coordinator.itemDisplayHandler = self.itemDisplayHandler
        context.coordinator.reusableItemDisplayHandler = self.reusableItemDisplayHandler
        context.coordinator.didSelectItemHandler = self.didSelectItemHandler
        if let mode = self.keyboardDismissModeValue {
            uiView.keyboardDismissMode = mode
        }

        uiView.apply(sections: self.sections.map { SwiftUISection($0) }, animated: self.animatingDifferences)
    }

    /// Registers a handler to be called just before a cell appears on screen.
    ///
    /// Useful for infinite-scroll pagination, impression logging, and similar tasks.
    ///
    /// - Parameter itemDisplayHandler: A closure that receives the model to be displayed and its index path.
    /// - Returns: A new ``DynamicCollectionView`` value with the handler applied.
    public func willDisplayItem(_ itemDisplayHandler: @escaping (_ item: any UICellConfigurableModel, _ indexPath: IndexPath) -> Void) -> Self {
        var copy = self
        copy.itemDisplayHandler = itemDisplayHandler
        return copy
    }

    /// Registers a handler to be called just before a supplementary view (header/footer) appears on screen.
    ///
    /// - Parameter reusableItemDisplayHandler: A closure that receives the supplementary model to be displayed and its index path.
    /// - Returns: A new ``DynamicCollectionView`` value with the handler applied.
    public func willDisplayReusableItem(_ reusableItemDisplayHandler: @escaping (_ item: any UIReusableViewConfigurableModel, _ indexPath: IndexPath) -> Void) -> Self {
        var copy = self
        copy.reusableItemDisplayHandler = reusableItemDisplayHandler
        return copy
    }

    /// Sets how the keyboard is dismissed while scrolling.
    ///
    /// - Parameter mode: The `UIScrollView.KeyboardDismissMode` to apply.
    /// - Returns: A new ``DynamicCollectionView`` value with the setting applied.
    public func keyboardDismissMode(_ mode: UIScrollView.KeyboardDismissMode) -> Self {
        var copy = self
        copy.keyboardDismissModeValue = mode
        return copy
    }

    /// Registers a handler to be called when an item is selected.
    ///
    /// - Parameter didSelectItemHandler: A closure that receives the selected model and its index path.
    /// - Returns: A new ``DynamicCollectionView`` value with the handler applied.
    public func didSelectItem(_ didSelectItemHandler: @escaping (_ item: any UICellConfigurableModel, _ indexPath: IndexPath) -> Void) -> Self {
        var copy = self
        copy.didSelectItemHandler = didSelectItemHandler
        return copy
    }
}

public extension DynamicCollectionView {
    /// A coordinator that relays ``DynamicCollectionView``'s UIKit delegate events to SwiftUI handlers.
    ///
    /// Receives `UICollectionViewDelegate` callbacks and forwards them to the latest
    /// handler closures injected in ``updateUIView(_:context:)``. It safely looks up the
    /// model by index path and invokes the corresponding closure only when one is present.
    class DynamicCollectionViewCoordinator: NSObject, UICollectionViewDelegate {

        var itemDisplayHandler: ((_ item: any UICellConfigurableModel, _ indexPath: IndexPath) -> Void)?

        var reusableItemDisplayHandler: ((_ item: any UIReusableViewConfigurableModel, _ indexPath: IndexPath) -> Void)?

        var didSelectItemHandler: ((_ item: any UICellConfigurableModel, _ indexPath: IndexPath) -> Void)?

        /// Called just before a cell is displayed, forwarding the model and index path to the registered display handler.
        ///
        /// - Parameters:
        ///   - collectionView: The collection view that sent the event.
        ///   - cell: The cell to be displayed.
        ///   - indexPath: The index path of the cell to be displayed.
        public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
            guard let collectionView = collectionView as? UIDynamicCollectionView,
                  let item = collectionView.currentSections[safe: indexPath.section]?.items[safe: indexPath.item]
            else { return }

            let handler = self.itemDisplayHandler

            DispatchQueue.main.async { handler?(item, indexPath) }
        }

        /// Called just before a supplementary view is displayed, forwarding the model and index path to the registered handler.
        ///
        /// - Parameters:
        ///   - collectionView: The collection view that sent the event.
        ///   - view: The supplementary view to be displayed.
        ///   - elementKind: The kind of supplementary element (header/footer).
        ///   - indexPath: The index path of the view to be displayed.
        public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
            guard let collectionView = collectionView as? UIDynamicCollectionView,
                  let item = collectionView.currentSections[safe: indexPath.section]?.reusableItems[elementKind]?[safe: indexPath.item]
            else { return }

            let handler = self.reusableItemDisplayHandler

            DispatchQueue.main.async { handler?(item, indexPath) }
        }

        /// Called when an item is selected, forwarding the model and index path to the registered selection handler.
        ///
        /// - Parameters:
        ///   - collectionView: The collection view that sent the event.
        ///   - indexPath: The index path of the selected item.
        public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard let collectionView = collectionView as? UIDynamicCollectionView,
                  let item = collectionView.currentSections[safe: indexPath.section]?.items[safe: indexPath.item]
            else { return }

            self.didSelectItemHandler?(item, indexPath)
        }
    }
}
