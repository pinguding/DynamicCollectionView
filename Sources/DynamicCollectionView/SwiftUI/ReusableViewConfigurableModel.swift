import Foundation

/// A data model protocol for configuring SwiftUI-based supplementary views (``ReusableView``).
///
/// By inheriting from `UIReusableViewConfigurableModel`, it declares via associated
/// types which SwiftUI supplementary view the model maps to and which
/// `UICollectionReusableView` type hosts that view.
///
/// - Note: This protocol does not require conformance to `ObservableObject`. A model that only
///   feeds immutable data into its view can stay a plain `final class`.
///
/// - Important: The model is the **single source of truth** for its supplementary view. A
///   ``ReusableView`` is hosted in a reused view and must not keep mutable state in
///   `@State`/`@Binding`. When state must mutate and persist across reuse, define it here:
///   adopt `ObservableObject`, mark properties `@Published`, and observe the model from the view
///   with `@ObservedObject`. See ``CellViewConfigurableModel`` and ``CellView`` for details.
public protocol ReusableViewConfigurableModel: UIReusableViewConfigurableModel {

    /// The type of the SwiftUI supplementary view configured by this model.
    associatedtype ReusableViewType: ReusableView

    /// The `UICollectionReusableView` type that hosts the model.
    ///
    /// The default is ``SwiftUIReusableView``, which wraps ``ReusableViewType`` in a
    /// `UIHostingController`.
    associatedtype UIReusableViewType = SwiftUIReusableView<ReusableViewType>
}
