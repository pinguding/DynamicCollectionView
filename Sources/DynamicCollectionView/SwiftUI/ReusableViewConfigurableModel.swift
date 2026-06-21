import Foundation

/// A data model protocol for configuring SwiftUI-based supplementary views (``ReusableView``).
///
/// By inheriting from `UIReusableViewConfigurableModel`, it declares via associated
/// types which SwiftUI supplementary view the model maps to and which
/// `UICollectionReusableView` type hosts that view.
///
/// - Note: This protocol does not require conformance to `ObservableObject`. Only when
///   you need to observe value changes should the model type adopt `ObservableObject` directly.
public protocol ReusableViewConfigurableModel: UIReusableViewConfigurableModel {

    /// The type of the SwiftUI supplementary view configured by this model.
    associatedtype ReusableViewType: ReusableView

    /// The `UICollectionReusableView` type that hosts the model.
    ///
    /// The default is ``SwiftUIReusableView``, which wraps ``ReusableViewType`` in a
    /// `UIHostingController`.
    associatedtype UIReusableViewType = SwiftUIReusableView<ReusableViewType>
}
