import UIKit

/// 서버 응답 등 외부 데이터에 따라 레이아웃이 동적으로 바뀔 수 있는 공통 컬렉션 뷰.
///
/// ``UICellConfigurableModel``, ``UIReusableViewConfigurableModel``, ``UISection``
/// 이 세 가지 데이터 모델만으로 컬렉션 뷰의 레이아웃을 구성할 수 있도록 설계되었다.
/// 세 모델 모두 프로토콜로 추상화되어 있어, 섹션 내부의 아이템(``UICellConfigurableModel``)과
/// 보충 뷰(``UIReusableViewConfigurableModel``)를 자유롭게 조합할 수 있다.
///
/// 내부적으로 `UICollectionViewDiffableDataSource`를 사용하며, 섹션이 apply될 때
/// 매칭되는 셀/보충 뷰를 자동으로 등록하므로 호출 측에서 별도의 register 작업이 필요 없다.
///
/// - Important: 이 타입은 `@MainActor`로 격리되어 모든 접근이 메인 스레드에서
///   이루어진다. 따라서 별도의 락 없이도 스레드 안전성이 보장된다.
@MainActor
public class UIDynamicCollectionView: UICollectionView {

    /// 셀/보충 뷰 디큐(dequeue)에 실패했을 때 크래시 대신 빈 UI를 노출하기 위한 식별자 모음.
    private enum Constants {
        /// 디큐 실패 시 사용할 빈 셀의 재사용 식별자.
        static let blankCellIdentifier: String = String(describing: UICollectionViewCell.self)
        /// 디큐 실패 시 사용할 빈 보충 뷰의 재사용 식별자.
        static let blankSupplementaryViewIdentifier: String = String(describing: UICollectionReusableView.self)
    }

    /// 현재 컬렉션 뷰에 적용되어 있는 섹션들.
    ///
    /// ``UIDynamicCollectionView``가 `@MainActor`로 격리되어 모든 접근이 메인 스레드에서
    /// 이루어지므로 별도의 락 없이도 안전하게 읽고 쓸 수 있다.
    public var currentSections: [any UISection] = []

    /// 컬렉션 뷰에 이미 등록된 컴포넌트의 재사용 식별자 집합.
    private var registeredComponent: Set<String> = []

    /// 컬렉션 뷰 내부에서 사용하는 디퍼블 데이터 소스.
    private var diffableDataSource: UICollectionViewDiffableDataSource<String, String>?

    /// 표시할 아이템이 없을 때 안내 문구를 보여주는 라벨.
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

    /// 커스텀 Compositional Layout 타입을 지정하여 컬렉션 뷰를 생성한다.
    ///
    /// 전달한 레이아웃 타입은 각 섹션의 ``UISection/sectionLayout(_:sectionIndex:environment:)``
    /// 결과를 이용해 섹션별 레이아웃을 구성한다.
    ///
    /// - Parameter layout: 사용할 `UICollectionViewCompositionalLayout` 하위 타입.
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

    /// 기본 `UICollectionViewCompositionalLayout`을 사용해 간편하게 생성하는 편의 이니셜라이저.
    ///
    /// 커스텀 레이아웃이 필요 없을 때 사용한다.
    convenience public init() {
        self.init(layout: UICollectionViewCompositionalLayout.self)
    }

    /// 스토리보드/NIB 기반 초기화는 지원하지 않는다.
    ///
    /// - Important: 호출 시 `fatalError`로 중단된다.
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 디큐 실패에 대비한 빈 셀과 빈 보충 뷰를 미리 등록한다.
    private func registerBlankComponents() {
        self.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Constants.blankCellIdentifier)
        self.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Constants.blankSupplementaryViewIdentifier)
        self.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: Constants.blankSupplementaryViewIdentifier)
    }

    /// 빈 상태 안내 라벨을 서브뷰로 추가하고 중앙 정렬 제약을 설정한다.
    private func configureEmptyGuideView() {
        self.addSubview(self.emptyItemGuideView)
        NSLayoutConstraint.activate([
            self.emptyItemGuideView.leftAnchor.constraint(greaterThanOrEqualTo: self.frameLayoutGuide.leftAnchor),
            self.emptyItemGuideView.rightAnchor.constraint(lessThanOrEqualTo: self.frameLayoutGuide.rightAnchor),
            self.emptyItemGuideView.centerXAnchor.constraint(equalTo: self.frameLayoutGuide.centerXAnchor),
            self.emptyItemGuideView.centerYAnchor.constraint(equalTo: self.frameLayoutGuide.centerYAnchor)
        ])
    }

    /// 모델로부터 1:1로 매칭되는 셀/보충 뷰를 디큐하도록 디퍼블 데이터 소스를 구성한다.
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

    /// 해당 인덱스의 ``UICellConfigurableModel``로부터 매칭되는 셀을 디큐하여 반환한다.
    ///
    /// 모델을 찾지 못하거나 구성에 실패하면 크래시 대신 빈 셀을 반환한다.
    ///
    /// - Parameters:
    ///   - collectionView: 셀을 디큐할 컬렉션 뷰.
    ///   - indexPath: 셀이 위치하는 인덱스 패스.
    ///   - itemIdentifier: 디퍼블 데이터 소스가 전달한 아이템 식별자.
    /// - Returns: 구성된 셀 또는 빈 셀.
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

    /// 해당 위치의 ``UIReusableViewConfigurableModel``로부터 매칭되는 보충 뷰를 디큐하여 반환한다.
    ///
    /// 모델을 찾지 못하거나 구성에 실패하면 크래시 대신 빈 보충 뷰를 반환한다.
    ///
    /// - Parameters:
    ///   - collectionView: 보충 뷰를 디큐할 컬렉션 뷰.
    ///   - elementKind: 보충 뷰의 종류(헤더/푸터 등).
    ///   - indexPath: 보충 뷰가 위치하는 인덱스 패스.
    /// - Returns: 구성된 보충 뷰 또는 빈 보충 뷰.
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

    /// 지정한 섹션 식별자들에 해당하는 섹션을 리로드한다.
    ///
    /// - Parameters:
    ///   - sectionIDs: 리로드할 섹션들의 식별자 배열.
    ///   - completion: 리로드 적용이 끝난 뒤 호출되는 클로저.
    public func reloadSection(_ sectionIDs: [String], completion: (() -> Void)? = nil) {
        guard var snapshot = self.diffableDataSource?.snapshot() else { return }

        snapshot.reloadSections(sectionIDs)

        self.diffableDataSource?.apply(snapshot, animatingDifferences: false, completion: completion)
    }

    /// 단일 섹션을 컬렉션 뷰에 적용한다.
    ///
    /// 내부적으로 ``apply(sections:animated:completion:)``을 호출한다.
    ///
    /// - Parameters:
    ///   - section: 적용할 섹션.
    ///   - animated: 변경을 애니메이션과 함께 적용할지 여부.
    ///   - completion: 적용이 끝난 뒤 호출되는 클로저.
    public func apply(_ section: any UISection, animated: Bool, completion: (() -> Void)? = nil) {
        self.apply(sections: [section], animated: animated, completion: completion)
    }

    /// 복수의 섹션을 컬렉션 뷰에 적용한다.
    ///
    /// 각 섹션에 필요한 셀/보충 뷰를 자동으로 등록한 뒤, 새 스냅샷을 만들어
    /// ``currentSections``를 교체하고 디퍼블 데이터 소스에 적용한다.
    ///
    /// - Parameters:
    ///   - sections: 적용할 섹션 배열. 기존 섹션을 대체한다.
    ///   - animated: 변경을 애니메이션과 함께 적용할지 여부.
    ///   - completion: 적용이 끝난 뒤 호출되는 클로저.
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

    /// 기존 스냅샷에 새로운 섹션들을 이어 붙인다.
    ///
    /// ``apply(sections:animated:completion:)``과 달리 기존 섹션을 대체하지 않고
    /// 현재 스냅샷 뒤에 추가한다.
    ///
    /// - Parameters:
    ///   - sections: 추가할 섹션 배열.
    ///   - animated: 변경을 애니메이션과 함께 적용할지 여부.
    ///   - completion: 적용이 끝난 뒤 호출되는 클로저.
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

    /// 지정한 섹션에 아이템들을 이어 붙인다.
    ///
    /// 대상 섹션이 ``currentSections``에 존재하지 않으면 디버그 빌드에서 `assert`로
    /// 중단되며, 릴리스 빌드에서는 아무 동작도 하지 않고 반환한다.
    ///
    /// - Parameters:
    ///   - items: 추가할 셀 모델 배열.
    ///   - sectionIdentifier: 아이템을 추가할 대상 섹션의 식별자.
    ///   - animated: 변경을 애니메이션과 함께 적용할지 여부.
    ///   - completion: 적용이 끝난 뒤 호출되는 클로저.
    public func append(items: [any UICellConfigurableModel], at sectionIdentifier: String, animated: Bool, completion: (() -> Void)? = nil) {
        assert(
            self.currentSections.contains(where: { $0.id == sectionIdentifier}),
            "Item 을 Append 할 Section이 존재하지 않습니다."
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

    /// 섹션의 셀과 보충 뷰 컴포넌트를 컬렉션 뷰에 등록한다.
    ///
    /// 이미 등록된 식별자는 ``registeredComponent`` 집합으로 걸러 한 번만 등록한다.
    /// 이 자동 등록 덕분에 호출 측에서 register 로직에 신경 쓰지 않아도 된다.
    ///
    /// - Parameter section: 컴포넌트를 등록할 섹션.
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

    /// 셀 모델들에 매칭되는 셀 타입을 컬렉션 뷰에 등록한다.
    ///
    /// 이미 등록된 식별자는 한 번만 등록한다.
    ///
    /// - Parameter items: 등록 대상이 되는 셀 모델 배열.
    private func registerItems(items: [any UICellConfigurableModel]) {
        items.forEach { model in
            let cellConfigurator = UICellConfigurator(model)

            if self.registeredComponent.insert(cellConfigurator.cellIdentifier).inserted == true {
                self.register(cellConfigurator.cellType, forCellWithReuseIdentifier: cellConfigurator.cellIdentifier)
            }
        }
    }
}
