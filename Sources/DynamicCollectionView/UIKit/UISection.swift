import UIKit

/// ``UIDynamicCollectionView``의 한 섹션을 구성하는 프로토콜.
///
/// 섹션은 자신의 식별자, 본문 아이템(``UICellConfigurableModel``), 보충 뷰
/// 아이템(``UIReusableViewConfigurableModel``), 그리고 레이아웃 정의를 담는다.
/// 모든 요소가 프로토콜로 추상화되어 있어 섹션 내부 구성을 자유롭게 조합할 수 있다.
///
/// - Note: 이 프로토콜은 의도적으로 `@MainActor`로 격리하지 않는다.
///   Reactor/ViewModel이 백그라운드 스레드에서 섹션을 조립할 수 있게 하기 위함이다.
///   스레드 안전성은 "백그라운드에서 완성 → 메인으로 불변 전달 →
///   메인에서 apply" 흐름으로 확보한다.
public protocol UISection: AnyObject {

    /// 보충 뷰 종류(element kind)를 가리키는 문자열 타입의 별칭.
    typealias ElementKind = String

    /// `UICollectionViewDiffableDataSource`에서 섹션 식별자로 사용될 값.
    var id: String { get }

    /// 섹션 본문에 배치되는 셀 모델들.
    var items: [any UICellConfigurableModel] { get set }

    /// element kind별로 그룹화된 섹션의 보충 뷰 모델들.
    var reusableItems: [ElementKind: [any UIReusableViewConfigurableModel]] { get set }

    /// 이 섹션의 Compositional Layout 섹션을 생성한다.
    ///
    /// - Parameters:
    ///   - collectionView: 레이아웃을 계산하는 컬렉션 뷰. 참조용으로 전달되며 nil일 수 있다.
    ///   - sectionIndex: 전체 레이아웃에서 이 섹션의 인덱스.
    ///   - environment: 레이아웃 계산에 필요한 환경 정보.
    /// - Returns: 구성된 `NSCollectionLayoutSection`.
    func sectionLayout(
        _ collectionView: UICollectionView?,
        sectionIndex: Int,
        environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection
}

/// 추상화된 ``UISection``을 ``UIDynamicCollectionView`` 내부에서 일시적으로 구체화하는 래퍼.
///
/// `any UISection`으로부터 섹션 식별자를 끌어내어 보관하며, `Hashable`을 채택해
/// 디퍼블 데이터 소스(snapshot)에서 다루기 쉽게 만든다. 표준 라이브러리의
/// `Hashable` 프로토콜과 `AnyHashable`의 관계와 유사한 역할을 한다.
///
/// - Important: 라이브러리 내부에서만 사용하는 `internal` 타입이다.
final internal class UISectionConfigurator: Hashable {

    /// 구체화의 대상이 된 원본 섹션.
    let base: any UISection

    /// 원본 섹션의 식별자.
    let id: String

    /// 섹션으로부터 식별자를 추출하여 래퍼를 만든다.
    ///
    /// - Parameter section: 구체화할 ``UISection``.
    init(_ section: any UISection) {
        self.base = section
        self.id = section.id
    }

    /// 두 래퍼가 같은 ``id``를 가지면 동일한 것으로 간주한다.
    static func == (lhs: UISectionConfigurator, rhs: UISectionConfigurator) -> Bool {
        lhs.id == rhs.id
    }

    /// ``id``를 해셔에 결합한다.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
