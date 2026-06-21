import Foundation

/// A result builder that declaratively collects item layouts.
///
/// Applied to the `items` closures of ``HGroupLayout`` and ``VGroupLayout``,
/// it gathers multiple ``ItemLayout`` values into an array.
@resultBuilder
public struct ItemLayoutBuilder {
    /// Bundles the listed item layouts into an array.
    ///
    /// - Parameter components: The item layouts listed in the builder body.
    /// - Returns: The collected array of item layouts.
    public static func buildBlock(_ components: (any ItemLayout)...) -> [any ItemLayout] {
        components
    }

    /// Forwards the result of the true (first) branch of an `if`.
    ///
    /// - Parameter component: The item layout array produced by the true branch.
    /// - Returns: The forwarded item layout array.
    public static func buildEither(first component: [any ItemLayout]) -> [any ItemLayout] {
        component
    }

    /// Forwards the result of the false (second) branch of an `else`.
    ///
    /// - Parameter component: The item layout array produced by the false branch.
    /// - Returns: The forwarded item layout array.
    public static func buildEither(second component: [any ItemLayout]) -> [any ItemLayout] {
        component
    }
}

/// A result builder that declaratively collects reusable view (header/footer) layouts.
///
/// Applied to the `header`/`footer` closures of ``GridSectionLayout`` and ``ListSectionLayout``,
/// it gathers multiple ``ReusableLayout`` values into an array and supports optional branches.
@resultBuilder
public struct ReusableViewLayoutBuilder {
    /// Bundles the listed reusable view layouts into an array.
    ///
    /// - Parameter components: The reusable view layouts listed in the builder body.
    /// - Returns: The collected array of reusable view layouts.
    public static func buildBlock(_ components: (any ReusableLayout)...) -> [any ReusableLayout] {
        components
    }

    /// Forwards the result of the true (first) branch of an `if`.
    ///
    /// - Parameter component: The reusable view layout array produced by the true branch.
    /// - Returns: The forwarded reusable view layout array.
    public static func buildEither(first component: [any ReusableLayout]) -> [any ReusableLayout] {
        component
    }

    /// Forwards the result of the false (second) branch of an `else`.
    ///
    /// - Parameter component: The reusable view layout array produced by the false branch.
    /// - Returns: The forwarded reusable view layout array.
    public static func buildEither(second component: [any ReusableLayout]) -> [any ReusableLayout] {
        component
    }

    /// Handles a single optional reusable view layout.
    ///
    /// - Parameter component: A reusable view layout that may or may not be present depending on a condition.
    /// - Returns: An array containing the value if present, otherwise an empty array.
    public static func buildOptional(_ component: (any ReusableLayout)?) -> [any ReusableLayout] {
        if let component {
            return [component]
        } else {
            return []
        }
    }

    /// Handles an optional array of reusable view layouts.
    ///
    /// - Parameter components: A reusable view layout array that may or may not be present depending on a condition.
    /// - Returns: The array if present, otherwise an empty array.
    public static func buildOptional(_ components: [any ReusableLayout]?) -> [any ReusableLayout] {
        return components ?? []
    }
}
