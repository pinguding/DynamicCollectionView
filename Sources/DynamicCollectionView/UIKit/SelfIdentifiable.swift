import Foundation

/// A protocol that provides a string identifying the type itself.
///
/// Use this when each object type needs a unique reuse identifier, such as
/// cells or reusable views. A default implementation is provided, so simply
/// conforming lets you use the type name as the identifier without any
/// additional implementation.
public protocol SelfIdentifiable {

    /// A string that identifies the type.
    ///
    /// Used as the reuse identifier when registering or dequeuing
    /// components in a collection view.
    static var selfIdentifier: String { get }
}

public extension SelfIdentifiable {

    /// The default implementation that builds and returns the type name using `String(describing:)`.
    static var selfIdentifier: String {
        String(describing: Self.self)
    }
}
