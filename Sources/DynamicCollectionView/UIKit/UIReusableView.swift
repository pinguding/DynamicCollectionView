import UIKit

/// ``UIDynamicCollectionView``에서 사용할 수 있도록 `UICollectionReusableView`가 채택하는 프로토콜.
///
/// 헤더나 푸터 같은 보충 뷰(supplementary view)를 추상화하며, 자신과 1:1로
/// 매칭되는 ``Model``을 통해 구성된다. ``SelfIdentifiable``을 함께 채택하므로
/// 타입 이름이 재사용 식별자로 사용된다.
public protocol UIReusableView: UICollectionReusableView, SelfIdentifiable {

    /// 이 재사용 뷰를 구성하는 데 사용되는 모델 타입.
    associatedtype Model: UIReusableViewConfigurableModel

    /// 이 뷰가 표현하는 보충 요소의 종류(element kind).
    ///
    /// 예: `UICollectionView.elementKindSectionHeader`,
    /// `UICollectionView.elementKindSectionFooter`.
    static var elementKind: String { get }

    /// 주어진 모델로 뷰의 내용을 구성한다.
    ///
    /// - Parameters:
    ///   - model: 뷰에 표시할 데이터를 담은 모델.
    ///   - indexPath: 뷰가 위치하는 인덱스 패스.
    func configure(model: Model, at indexPath: IndexPath)
}
