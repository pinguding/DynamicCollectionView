import UIKit

/// 레이아웃 콜백에서 전달되는 가시 아이템 타입.
///
/// `NSCollectionLayoutVisibleItem` 의 별칭으로, ``GridSectionLayout/visibleItem(_:)`` 핸들러에서 사용된다.
public typealias CollectionVisibleItem = NSCollectionLayoutVisibleItem

/// 레이아웃 빌드 시점에 전달되는 레이아웃 환경 타입.
///
/// `NSCollectionLayoutEnvironment` 의 별칭으로, 컨테이너 크기 등 레이아웃 계산에 필요한 정보를 담는다.
public typealias CollectionLayoutEnvironment = NSCollectionLayoutEnvironment

/// 하나의 섹션을 선언적으로 정의하는 프로토콜.
///
/// 섹션의 식별자, 셀 모델, 재사용(헤더/푸터) 모델, 그리고 레이아웃을 묶어
/// ``SwiftUISection`` 을 통해 컬렉션 뷰에 반영한다.
///
/// - Note: 이 프로토콜은 의도적으로 `@MainActor` 가 아니다.
///   ViewModel 이나 Reactor 가 백그라운드 스레드에서 섹션을 조립할 수 있도록
///   메인 액터 격리를 두지 않았다. UI 반영 시점에만 메인 액터로 넘어간다.
public protocol SectionContext {

    /// 재사용 뷰(헤더/푸터)를 구분하는 엘리먼트 종류 키 타입.
    typealias ElementKind = String

    /// 이 섹션이 사용하는 섹션 레이아웃의 구체 타입.
    associatedtype Layout: SectionLayout

    /// 섹션을 식별하는 고유 문자열.
    var id: String { get }

    /// 섹션에 표시할 셀 모델 목록.
    var items: [any CellViewConfigurableModel] { get set }

    /// 엘리먼트 종류별 재사용 뷰(헤더/푸터) 모델 목록.
    var reusableItems: [ElementKind: [any ReusableViewConfigurableModel]] { get set }

    /// 섹션의 레이아웃 정의.
    var layout: Layout { get }
}

/// 커스텀(워터폴 등) 레이아웃을 사용하는 섹션을 위한 확장 프로토콜.
///
/// 가변 높이 레이아웃 계산에 필요한 커스텀 셀 모델과
/// 계산 결과 캐시(컬럼 높이, 프레임)를 추가로 보관한다.
public protocol CustomLayoutSectionContext: SectionContext {

    /// 커스텀 레이아웃에 표시할 셀 모델 목록.
    var customItems: [any CustomLayoutCellViewConfigurableModel] { get set }

    /// 워터폴 계산 시 각 컬럼의 누적 높이 캐시.
    var cachedHeightColumns: [CGFloat] { get set }

    /// 워터폴 계산 결과로 산출된 프레임 캐시.
    var cachedFrame: CGRect { get set }
}

public extension CustomLayoutSectionContext {

    /// ``customItems`` 를 ``SectionContext/items`` 요구사항에 연결하는 기본 구현.
    ///
    /// 읽을 때는 커스텀 모델을 일반 셀 모델로 업캐스트하고,
    /// 쓸 때는 커스텀 모델로 다운캐스트하여 저장한다.
    var items: [any CellViewConfigurableModel] {
        get {
            self.customItems as [any CellViewConfigurableModel]
        } set {
            self.customItems = newValue as? [any CustomLayoutCellViewConfigurableModel] ?? []
        }
    }
}


/// ``SectionContext`` 를 `UISection` 으로 잇는 브리지 클래스.
///
/// 선언형 ``SectionContext`` 를 받아 컬렉션 뷰가 요구하는 `UISection` 인터페이스로 변환하며,
/// 레이아웃 빌드 요청을 내부 ``SectionLayout`` 으로 위임한다.
public class SwiftUISection: UISection {

    /// 섹션 식별자.
    public let id: String

    /// 셀 구성 모델 목록.
    public var items: [any UICellConfigurableModel]

    /// 엘리먼트 종류별 재사용 뷰 구성 모델 목록.
    public var reusableItems: [ElementKind : [any UIReusableViewConfigurableModel]]

    private let section: any SectionContext

    /// ``SectionContext`` 를 감싸 브리지를 생성한다.
    ///
    /// - Parameter section: 변환할 대상 섹션 정의.
    public init(_ section: any SectionContext) {
        self.id = section.id
        self.section = section
        self.items = section.items
        self.reusableItems = section.reusableItems
    }

    /// 감싼 섹션의 레이아웃을 `NSCollectionLayoutSection` 으로 빌드한다.
    ///
    /// - Parameters:
    ///   - collectionView: 레이아웃을 적용할 컬렉션 뷰.
    ///   - sectionIndex: 전체 레이아웃에서 이 섹션의 인덱스.
    ///   - environment: 레이아웃 계산에 사용할 환경.
    /// - Returns: 빌드된 `NSCollectionLayoutSection`.
    public func sectionLayout(_ collectionView: UICollectionView?, sectionIndex: Int, environment: any NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        self.section.layout._buildSectionLayout(index: sectionIndex, environment: environment)
    }
}
