import UIKit

/// ``UIDynamicCollectionView``에서 사용할 수 있도록 `UICollectionViewCell`이 채택하는 프로토콜.
///
/// 이 프로토콜을 채택한 셀은 자신과 1:1로 매칭되는 ``Model``을 통해 구성된다.
/// ``SelfIdentifiable``을 함께 채택하므로 별도 식별자 지정 없이 타입 이름이
/// 재사용 식별자로 사용된다.
///
/// ```swift
/// final class ProductCell: UICollectionViewCell, UICell {
///     func configure(model: ProductCellModel, at indexPath: IndexPath) {
///         // 모델로부터 셀의 UI를 구성한다.
///     }
/// }
/// ```
public protocol UICell: UICollectionViewCell, SelfIdentifiable {

    /// 이 셀을 구성하는 데 사용되는 모델 타입.
    associatedtype Model: UICellConfigurableModel

    /// 주어진 모델로 셀의 내용을 구성한다.
    ///
    /// - Parameters:
    ///   - model: 셀에 표시할 데이터를 담은 모델.
    ///   - indexPath: 셀이 위치하는 인덱스 패스.
    func configure(model: Model, at indexPath: IndexPath)
}
