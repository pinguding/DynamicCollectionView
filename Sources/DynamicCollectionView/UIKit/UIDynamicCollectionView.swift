import UIKit

/// A common collection view whose layout can change dynamically based on external data such as server responses.
///
/// It is designed so that a collection view's layout can be composed using only
/// the three data models ``UICellConfigurableModel``, ``UIReusableViewConfigurableModel``,
/// and ``UISection``. All three models are abstracted as protocols, so items
/// inside a section (``UICellConfigurableModel``) and supplementary views
/// (``UIReusableViewConfigurableModel``) can be combined freely.
///
/// Internally it uses `UICollectionViewDiffableDataSource`, and it automatically
/// registers the matching cells/supplementary views when a section is applied,
/// so the call site needs no separate register work.
///
/// - Important: This type is isolated to `@MainActor`, so all access occurs on
///   the main thread. Thread safety is therefore guaranteed without a separate lock.
@MainActor
public class UIDynamicCollectionView: UICollectionView {

    /// A collection of identifiers for showing an empty UI instead of crashing when dequeuing a cell/supplementary view fails.
    private enum Constants {
        /// The reuse identifier of the blank cell used when dequeue fails.
        static let blankCellIdentifier: String = String(describing: UICollectionViewCell.self)
        /// The reuse identifier of the blank supplementary view used when dequeue fails.
        static let blankSupplementaryViewIdentifier: String = String(describing: UICollectionReusableView.self)
    }

    /// The sections currently applied to the collection view.
    ///
    /// Since ``UIDynamicCollectionView`` is isolated to `@MainActor` and all access
    /// occurs on the main thread, it can be read and written safely without a separate lock.
    public var currentSections: [any UISection] = []

    /// The set of reuse identifiers of components already registered with the collection view.
    private var registeredComponent: Set<String> = []

    /// The diffable data source used internally by the collection view.
    private var diffableDataSource: UICollectionViewDiffableDataSource<String, String>?

    /// A label that shows a guidance message when there are no items to display.
    private let emptyItemGuideView: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.isHidden = true
        return label
    }()

    /// Creates the collection view by specifying a custom Compositional Layout type.
    ///
    /// The provided layout type composes each section's layout using the result of
    /// each section's ``UISection/sectionLayout(_:sectionIndex:environment:)``.
    ///
    /// - Parameter layout: The `UICollectionViewCompositionalLayout` subtype to use.
    public required init<Layout: UICollectionViewCompositionalLayout>(layout: Layout.Type) {
        super.init(frame: .zero, collectionViewLayout: .init())

        self.collectionViewLayout = Layout { [weak self] sectionIndex, environment in
            guard let self, let section = self.currentSections[safe: sectionIndex] else { return nil }

            let sectionLayout = section.sectionLayout(self, sectionIndex: sectionIndex, environment: environment)

            return sectionLayout
        }

        self.configureEmptyGuideView()
        self.configureDiffableDataSource()
        self.registerBlankComponents()
    }

    /// A convenience initializer for easy creation using the default `UICollectionViewCompositionalLayout`.
    ///
    /// Use this when no custom layout is needed.
    convenience public init() {
        self.init(layout: UICollectionViewCompositionalLayout.self)
    }

    /// Storyboard/NIB-based initialization is not supported.
    ///
    /// - Important: Aborts with `fatalError` when called.
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Pre-registers a blank cell and blank supplementary view to guard against dequeue failures.
    private func registerBlankComponents() {
        self.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Constants.blankCellIdentifier)
        self.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Constants.blankSupplementaryViewIdentifier)
        self.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: Constants.blankSupplementaryViewIdentifier)
    }

    /// Adds the empty-state guide label as a subview and sets up center-alignment constraints.
    private func configureEmptyGuideView() {
        self.addSubview(self.emptyItemGuideView)
        NSLayoutConstraint.activate([
            self.emptyItemGuideView.leftAnchor.constraint(greaterThanOrEqualTo: self.frameLayoutGuide.leftAnchor),
            self.emptyItemGuideView.rightAnchor.constraint(lessThanOrEqualTo: self.frameLayoutGuide.rightAnchor),
            self.emptyItemGuideView.centerXAnchor.constraint(equalTo: self.frameLayoutGuide.centerXAnchor),
            self.emptyItemGuideView.centerYAnchor.constraint(equalTo: self.frameLayoutGuide.centerYAnchor)
        ])
    }

    /// Configures the diffable data source to dequeue cells/supplementary views that match models one-to-one.
    private func configureDiffableDataSource() {
        self.diffableDataSource = .init(
            collectionView: self,
            cellProvider: { [weak self] collectionView, indexPath, itemIdentifier -> UICollectionViewCell? in
                self?.collectionViewCell(collectionView, at: indexPath, with: itemIdentifier)
            }
        )

        self.diffableDataSource?
            .supplementaryViewProvider = { [weak self] collectionView, kind, indexPath -> UICollectionReusableView? in
                self?.collectionViewSupplementaryView(collectionView, kind: kind, at: indexPath)
            }
    }

    /// Dequeues and returns the cell matching the ``UICellConfigurableModel`` at the given index.
    ///
    /// If the model cannot be found or configuration fails, it returns a blank cell instead of crashing.
    ///
    /// - Parameters:
    ///   - collectionView: The collection view from which to dequeue the cell.
    ///   - indexPath: The index path where the cell is located.
    ///   - itemIdentifier: The item identifier passed by the diffable data source.
    /// - Returns: The configured cell, or a blank cell.
    private func collectionViewCell(
        _ collectionView: UICollectionView,
        at indexPath: IndexPath,
        with itemIdentifier: String
    ) -> UICollectionViewCell? {
        guard let cellConfigurableModel = self.currentSections[safe: indexPath.section]?.items[indexPath.item]
        else {
            return self.dequeueReusableCell(withReuseIdentifier: Constants.blankCellIdentifier, for: indexPath)
        }

        let configurator = UICellConfigurator(cellConfigurableModel)

        let dequeuedCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: configurator.cellIdentifier,
            for: indexPath
        )

        guard let cell = configurator.base.configuredCell(dequeuedCell, at: indexPath) else {
            return self.dequeueReusableCell(withReuseIdentifier: Constants.blankCellIdentifier, for: indexPath)
        }

        return cell
    }

    /// Dequeues and returns the supplementary view matching the ``UIReusableViewConfigurableModel`` at the given position.
    ///
    /// If the model cannot be found or configuration fails, it returns a blank supplementary view instead of crashing.
    ///
    /// - Parameters:
    ///   - collectionView: The collection view from which to dequeue the supplementary view.
    ///   - elementKind: The kind of supplementary view (header/footer, etc.).
    ///   - indexPath: The index path where the supplementary view is located.
    /// - Returns: The configured supplementary view, or a blank supplementary view.
    private func collectionViewSupplementaryView(
        _ collectionView: UICollectionView,
        kind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView? {
        guard let supplementaryConfigurableModel = self.currentSections[safe: indexPath.section]?.reusableItems[elementKind]?[safe: indexPath.item]
        else {
            return self.dequeueReusableSupplementaryView(
                ofKind: elementKind,
                withReuseIdentifier: Constants.blankSupplementaryViewIdentifier,
                for: indexPath
            )
        }

        let configurator = UIReusableViewConfigurator(supplementaryConfigurableModel)

        let dequeuedSupplementaryView = collectionView.dequeueReusableSupplementaryView(
            ofKind: elementKind,
            withReuseIdentifier: configurator.supplementaryViewIdentifier,
            for: indexPath
        )

        guard let view = configurator.base.configuredSupplementaryView(dequeuedSupplementaryView, indexPath: indexPath) else {
            return self.dequeueReusableSupplementaryView(
                ofKind: elementKind,
                withReuseIdentifier: Constants.blankSupplementaryViewIdentifier,
                for: indexPath
            )
        }

        return view
    }
}

extension UIDynamicCollectionView {

    /// Reloads the sections corresponding to the given section identifiers.
    ///
    /// - Parameters:
    ///   - sectionIDs: The array of identifiers of the sections to reload.
    ///   - completion: A closure called after the reload has been applied.
    public func reloadSection(_ sectionIDs: [String], completion: (() -> Void)? = nil) {
        guard var snapshot = self.diffableDataSource?.snapshot() else { return }

        snapshot.reloadSections(sectionIDs)

        self.diffableDataSource?.apply(snapshot, animatingDifferences: false, completion: completion)
    }

    /// Applies a single section to the collection view.
    ///
    /// Internally calls ``apply(sections:animated:completion:)``.
    ///
    /// - Parameters:
    ///   - section: The section to apply.
    ///   - animated: Whether to apply the change with animation.
    ///   - completion: A closure called after the change has been applied.
    public func apply(_ section: any UISection, animated: Bool, completion: (() -> Void)? = nil) {
        self.apply(sections: [section], animated: animated, completion: completion)
    }

    /// Applies multiple sections to the collection view.
    ///
    /// After automatically registering the cells/supplementary views needed for each
    /// section, it creates a new snapshot, replaces ``currentSections``, and applies
    /// it to the diffable data source.
    ///
    /// - Parameters:
    ///   - sections: The array of sections to apply. Replaces the existing sections.
    ///   - animated: Whether to apply the change with animation.
    ///   - completion: A closure called after the change has been applied.
    public func apply(sections: [any UISection], animated: Bool, completion: (() -> Void)? = nil) {
        sections.forEach { section in
            self.registerComponents(section: section)
        }

        let sectionConfigurators = sections.map { UISectionConfigurator($0) }
        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        snapshot.appendSections(sectionConfigurators.map(\.id))
        sectionConfigurators.forEach { section in
            snapshot.appendItems(section.base.items.map(\.id), toSection: section.id)
        }

        self.currentSections = sections

        self.diffableDataSource?.apply(snapshot, animatingDifferences: animated) {
            completion?()
        }
    }

    /// Appends new sections to the existing snapshot.
    ///
    /// Unlike ``apply(sections:animated:completion:)``, it does not replace the
    /// existing sections but appends them after the current snapshot.
    ///
    /// - Parameters:
    ///   - sections: The array of sections to append.
    ///   - animated: Whether to apply the change with animation.
    ///   - completion: A closure called after the change has been applied.
    public func append(sections: [any UISection], animated: Bool, completion: (() -> Void)? = nil) {
        guard let diffableDataSource else { return }

        sections.forEach { section in
            self.registerComponents(section: section)
        }
        var snapshot = diffableDataSource.snapshot()
        let sectionConfigurators = sections.map { UISectionConfigurator($0) }
        snapshot.appendSections(sectionConfigurators.map(\.id))
        sectionConfigurators.forEach { configurator in
            snapshot.appendItems(configurator.base.items.map(\.id), toSection: configurator.id)
        }

        diffableDataSource.apply(snapshot, animatingDifferences: animated, completion: completion)
    }

    /// Appends items to the specified section.
    ///
    /// If the target section does not exist in ``currentSections``, it aborts via
    /// `assert` in debug builds, and in release builds it returns without doing anything.
    ///
    /// - Parameters:
    ///   - items: The array of cell models to append.
    ///   - sectionIdentifier: The identifier of the target section to append the items to.
    ///   - animated: Whether to apply the change with animation.
    ///   - completion: A closure called after the change has been applied.
    public func append(items: [any UICellConfigurableModel], at sectionIdentifier: String, animated: Bool, completion: (() -> Void)? = nil) {
        assert(
            self.currentSections.contains(where: { $0.id == sectionIdentifier}),
            "The section to append items to does not exist."
        )
        guard let diffableDataSource,
              let section = self.currentSections.first(where: { $0.id == sectionIdentifier }) else {
            return
        }

        section.items.append(contentsOf: items)
        self.registerComponents(section: section)

        var snapshot = diffableDataSource.snapshot()
        snapshot.appendItems(items.map(\.id), toSection: sectionIdentifier)

        diffableDataSource.apply(snapshot, animatingDifferences: animated, completion: completion)
    }

    /// Registers the section's cell and supplementary view components with the collection view.
    ///
    /// Already-registered identifiers are filtered out using the ``registeredComponent``
    /// set so each is registered only once. Thanks to this automatic registration,
    /// the call site does not have to worry about register logic.
    ///
    /// - Parameter section: The section whose components are to be registered.
    private func registerComponents(section: any UISection) {
        self.registerItems(items: section.items)

        let supplementaryViews = section.reusableItems.map(\.value).reduce([], +)

        supplementaryViews.forEach { model in
            let configurator = UIReusableViewConfigurator(model)

            if self.registeredComponent.insert(configurator.supplementaryViewIdentifier).inserted == true {
                self.register(
                    configurator.supplementaryViewType,
                    forSupplementaryViewOfKind: configurator.elementKind,
                    withReuseIdentifier: configurator.supplementaryViewIdentifier
                )
            }
        }
    }

    /// Registers the cell types matching the cell models with the collection view.
    ///
    /// Already-registered identifiers are registered only once.
    ///
    /// - Parameter items: The array of cell models to register.
    private func registerItems(items: [any UICellConfigurableModel]) {
        items.forEach { model in
            let cellConfigurator = UICellConfigurator(model)

            if self.registeredComponent.insert(cellConfigurator.cellIdentifier).inserted == true {
                self.register(cellConfigurator.cellType, forCellWithReuseIdentifier: cellConfigurator.cellIdentifier)
            }
        }
    }
}
