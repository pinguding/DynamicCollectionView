import UIKit

/// A protocol that composes a single section of ``UIDynamicCollectionView``.
///
/// A section holds its identifier, body items (``UICellConfigurableModel``),
/// supplementary view items (``UIReusableViewConfigurableModel``), and its layout
/// definition. Since every element is abstracted as a protocol, the internal
/// composition of a section can be combined freely.
///
/// - Note: This protocol is intentionally not isolated to `@MainActor`.
///   This allows a Reactor/ViewModel to assemble sections on a background thread.
///   Thread safety is ensured through the flow of "complete in the background →
///   hand off immutably to main → apply on main".
public protocol UISection: AnyObject {

    /// A type alias for the string type that denotes a supplementary view's element kind.
    typealias ElementKind = String

    /// The value used as the section identifier in `UICollectionViewDiffableDataSource`.
    var id: String { get }

    /// The cell models placed in the section's body.
    var items: [any UICellConfigurableModel] { get set }

    /// The section's supplementary view models grouped by element kind.
    var reusableItems: [ElementKind: [any UIReusableViewConfigurableModel]] { get set }

    /// Creates the Compositional Layout section for this section.
    ///
    /// - Parameters:
    ///   - collectionView: The collection view that calculates the layout. Passed for reference and may be nil.
    ///   - sectionIndex: The index of this section within the overall layout.
    ///   - environment: The environment information needed for layout calculation.
    /// - Returns: The configured `NSCollectionLayoutSection`.
    func sectionLayout(
        _ collectionView: UICollectionView?,
        sectionIndex: Int,
        environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection
}

/// A wrapper that temporarily concretizes an abstracted ``UISection`` inside ``UIDynamicCollectionView``.
///
/// It extracts and stores the section identifier from an `any UISection`, and
/// conforms to `Hashable` to make it easy to handle in a diffable data source
/// (snapshot). It plays a role similar to the relationship between the standard
/// library's `Hashable` protocol and `AnyHashable`.
///
/// - Important: This is an `internal` type used only within the library.
final internal class UISectionConfigurator: Hashable {

    /// The original section that was concretized.
    let base: any UISection

    /// The identifier of the original section.
    let id: String

    /// Creates the wrapper by extracting the identifier from the section.
    ///
    /// - Parameter section: The ``UISection`` to concretize.
    init(_ section: any UISection) {
        self.base = section
        self.id = section.id
    }

    /// Two wrappers are considered equal if they have the same ``id``.
    static func == (lhs: UISectionConfigurator, rhs: UISectionConfigurator) -> Bool {
        lhs.id == rhs.id
    }

    /// Combines ``id`` into the hasher.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
