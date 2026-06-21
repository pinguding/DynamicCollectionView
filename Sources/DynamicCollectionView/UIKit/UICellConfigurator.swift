import UIKit

/// 추상화된 ``UICellConfigurableModel``을 ``UIDynamicCollectionView`` 내부에서 일시적으로 구체화하는 래퍼.
///
/// 제네릭 컨텍스트가 사라진 `any UICellConfigurableModel`로부터 셀 식별자와
/// 셀 타입 같은 구체 정보를 한 번에 끌어내어 보관한다. `Hashable`을 채택하여
/// 디퍼블 데이터 소스(snapshot)에서 다루기 쉽게 만들며, 표준 라이브러리의
/// `Hashable` 프로토콜과 `AnyHashable`의 관계와 유사한 역할을 한다.
///
/// - Important: 라이브러리 내부에서만 사용하는 `internal` 타입이다.
final internal class UICellConfigurator: Hashable {

    /// 원본 모델의 식별자.
    let id: String

    /// 구체화의 대상이 된 원본 모델.
    let base: any UICellConfigurableModel

    /// 매칭되는 셀의 재사용 식별자.
    let cellIdentifier: String

    /// 매칭되는 셀의 구체 타입.
    let cellType: UICollectionViewCell.Type

    /// 구체 모델 타입으로부터 셀 식별자/타입과 식별자를 추출하여 래퍼를 만든다.
    ///
    /// - Parameter base: 구체화할 ``UICellConfigurableModel`` 모델.
    init<Model: UICellConfigurableModel>(_ base: Model) {
        self.base = base
        self.cellIdentifier = Model.CellType.selfIdentifier
        self.cellType = Model.CellType.self
        self.id = base.id
    }

    /// 두 래퍼가 같은 ``id``를 가지면 동일한 것으로 간주한다.
    static func == (lhs: UICellConfigurator, rhs: UICellConfigurator) -> Bool {
        lhs.id == rhs.id
    }

    /// ``id``를 해셔에 결합한다.
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
