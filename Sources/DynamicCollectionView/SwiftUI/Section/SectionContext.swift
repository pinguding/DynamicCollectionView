import UIKit

/// The visible item type passed to layout callbacks.
///
/// An alias for `NSCollectionLayoutVisibleItem`, used in the ``GridSectionLayout/visibleItem(_:)`` handler.
public typealias CollectionVisibleItem = NSCollectionLayoutVisibleItem

/// The layout environment type passed at layout build time.
///
/// An alias for `NSCollectionLayoutEnvironment`, carrying information needed for layout calculation such as the container size.
public typealias CollectionLayoutEnvironment = NSCollectionLayoutEnvironment

/// A protocol that declaratively defines a single section.
///
/// It bundles the section's identifier, cell models, reusable (header/footer) models, and layout,
/// then reflects them into the collection view through ``SwiftUISection``.
///
/// - Note: This protocol is intentionally not `@MainActor`.
///   Main-actor isolation is omitted so that a ViewModel or Reactor can assemble sections
///   on a background thread. It only crosses over to the main actor when reflecting into the UI.
public protocol SectionContext {

    /// The element kind key type that distinguishes reusable views (header/footer).
    typealias ElementKind = String

    /// The concrete section layout type used by this section.
    associatedtype Layout: SectionLayout

    /// The unique string that identifies the section.
    var id: String { get }

    /// The list of cell models to display in the section.
    var items: [any CellViewConfigurableModel] { get set }

    /// The list of reusable view (header/footer) models keyed by element kind.
    var reusableItems: [ElementKind: [any ReusableViewConfigurableModel]] { get set }

    /// The section's layout definition.
    var layout: Layout { get }
}

/// An extended protocol for sections that use a custom layout, such as a waterfall.
///
/// It additionally holds the custom cell models needed for variable-height layout calculation
/// and the calculation result cache (column heights, frame).
public protocol CustomLayoutSectionContext: SectionContext {

    /// The list of cell models to display in the custom layout.
    var customItems: [any CustomLayoutCellViewConfigurableModel] { get set }

    /// The cumulative height cache for each column during waterfall calculation.
    var cachedHeightColumns: [CGFloat] { get set }

    /// The frame cache produced by the waterfall calculation.
    var cachedFrame: CGRect { get set }
}

public extension CustomLayoutSectionContext {

    /// The default implementation that connects ``customItems`` to the ``SectionContext/items`` requirement.
    ///
    /// On read, it upcasts the custom models to plain cell models;
    /// on write, it downcasts to custom models before storing.
    var items: [any CellViewConfigurableModel] {
        get {
            self.customItems as [any CellViewConfigurableModel]
        } set {
            self.customItems = newValue as? [any CustomLayoutCellViewConfigurableModel] ?? []
        }
    }
}


/// A bridge class that connects a ``SectionContext`` to a `UISection`.
///
/// It takes a declarative ``SectionContext`` and converts it into the `UISection` interface required by the collection view,
/// delegating layout build requests to the underlying ``SectionLayout``.
public class SwiftUISection: UISection {

    /// The section identifier.
    public let id: String

    /// The list of cell configuration models.
    public var items: [any UICellConfigurableModel]

    /// The list of reusable view configuration models keyed by element kind.
    public var reusableItems: [ElementKind : [any UIReusableViewConfigurableModel]]

    private let section: any SectionContext

    /// Creates the bridge by wrapping a ``SectionContext``.
    ///
    /// - Parameter section: The target section definition to convert.
    public init(_ section: any SectionContext) {
        self.id = section.id
        self.section = section
        self.items = section.items
        self.reusableItems = section.reusableItems
    }

    /// Builds the wrapped section's layout into an `NSCollectionLayoutSection`.
    ///
    /// - Parameters:
    ///   - collectionView: The collection view to apply the layout to.
    ///   - sectionIndex: The index of this section within the overall layout.
    ///   - environment: The environment used for layout calculation.
    /// - Returns: The built `NSCollectionLayoutSection`.
    public func sectionLayout(_ collectionView: UICollectionView?, sectionIndex: Int, environment: any NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        self.section.layout._buildSectionLayout(index: sectionIndex, environment: environment)
    }
}
