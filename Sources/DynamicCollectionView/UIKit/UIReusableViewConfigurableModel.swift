import UIKit

/// ``UIDynamicCollectionView``에서 ``UIReusableView``를 디큐(dequeue)하고 구성하는 데 사용되는 모델 프로토콜.
///
/// 연관 타입 ``UIReusableViewType``을 통해 모델과 보충 뷰를 1:1로 연결한다.
/// 헤더/푸터 등 보충 요소의 데이터 표현을 담당한다.
///
/// - Note: 이 프로토콜은 의도적으로 `@MainActor`로 격리하지 않는다.
///   Reactor/ViewModel이 백그라운드 스레드에서 섹션과 모델을 조립할 수 있게
///   하기 위함이며, 스레드 안전성은 "백그라운드 조립 → 메인으로 전달 →
///   메인에서 apply" 흐름으로 확보한다.
public protocol UIReusableViewConfigurableModel: AnyObject {

    /// 이 모델과 매칭되는 재사용 뷰 타입.
    associatedtype UIReusableViewType: UIReusableView

    /// 이 모델을 식별하는 값.
    var id: String { get }

    /// 디큐된 보충 뷰를 ``UIReusableViewType``으로 캐스팅하고 이 모델로 구성하여 반환한다.
    ///
    /// - Parameters:
    ///   - dequeuedSupplementaryView: CollectionView로부터 디큐된 보충 뷰.
    ///   - indexPath: 뷰가 위치하는 인덱스 패스.
    /// - Returns: 구성에 성공한 ``UIReusableViewType`` 뷰. 캐스팅에 실패하면 `nil`.
    func configuredSupplementaryView(_ dequeuedSupplementaryView: UICollectionReusableView, indexPath: IndexPath) -> UIReusableViewType?
}

public extension UIReusableViewConfigurableModel {

    /// 디큐된 보충 뷰와 자기 자신을 각각 ``UIReusableViewType``과 그 모델 타입으로
    /// 캐스팅한 뒤 `configure(model:at:)`를 호출해 뷰를 구성하는 기본 구현.
    ///
    /// - Parameters:
    ///   - dequeuedSupplementaryView: CollectionView로부터 디큐된 보충 뷰.
    ///   - indexPath: 뷰가 위치하는 인덱스 패스.
    /// - Returns: 구성된 뷰. 뷰 또는 모델 캐스팅에 실패하면 `nil`.
    func configuredSupplementaryView(_ dequeuedSupplementaryView: UICollectionReusableView, indexPath: IndexPath)
    -> UIReusableViewType? {
        guard let supplementaryView = dequeuedSupplementaryView as? UIReusableViewType,
              let transformedModel = self as? UIReusableViewType.Model
        else { return nil }

        supplementaryView.configure(model: transformedModel, at: indexPath)
        return supplementaryView
    }
}
