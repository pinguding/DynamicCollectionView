import UIKit

/// An enumeration that represents a layout dimension.
///
/// It maps to `NSCollectionLayoutDimension` and is used to specify width and height.
public enum LayoutSize {
    /// A dimension specified as a fraction (0–1) of the container width.
    case fractionalWidth(CGFloat)
    /// A dimension specified as a fraction (0–1) of the container height.
    case fractionalHeight(CGFloat)
    /// A dimension specified as an estimate. It adjusts automatically based on the actual content.
    case estimated(CGFloat)
    /// A dimension specified as a fixed value in points.
    case absolute(CGFloat)
}

extension LayoutSize {
    /// The value converted to the corresponding `NSCollectionLayoutDimension`.
    var nsCollectionLayoutDimension: NSCollectionLayoutDimension {
        switch self {
        case let .fractionalWidth(value):
            return .fractionalWidth(value)
        case let .fractionalHeight(value):
            return .fractionalHeight(value)
        case let .estimated(value):
            return .estimated(value)
        case let .absolute(value):
            return .absolute(value)
        }
    }
}
