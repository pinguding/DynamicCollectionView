import Foundation

extension Array {
    /// A subscript that safely returns an element without crashing even when accessed with an out-of-range index.
    ///
    /// Unlike ordinary subscript access, when given an index outside the valid range
    /// (`indices`), it returns `nil` instead of trapping the program. This is a
    /// library-internal helper to prevent crashes in places that need bounds checking,
    /// such as collection views where indices can change asynchronously.
    ///
    /// - Parameter index: The index of the element to access.
    /// - Returns: The element if `index` is within the valid range, or `nil` if out of range.
    subscript(safe index: Int) -> Element? {
        indices ~= index ? self[index] : nil
    }
}
