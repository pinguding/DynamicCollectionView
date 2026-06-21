import Foundation

/// SwiftUI 기반 서플먼터리 뷰(``ReusableView``)를 구성하기 위한 데이터 모델 프로토콜.
///
/// `UIReusableViewConfigurableModel` 을 상속하여, 모델이 어떤 SwiftUI 서플먼터리
/// 뷰와 그 뷰를 호스팅하는 `UICollectionReusableView` 타입에 매핑되는지를
/// 연관타입으로 선언합니다.
///
/// - Note: 이 프로토콜은 `ObservableObject` 채택을 요구하지 않습니다. 값 변화를
///   관찰해야 할 때에만 모델 타입이 직접 `ObservableObject` 를 채택하면 됩니다.
public protocol ReusableViewConfigurableModel: UIReusableViewConfigurableModel {

    /// 이 모델로 구성되는 SwiftUI 서플먼터리 뷰의 타입.
    associatedtype ReusableViewType: ReusableView

    /// 모델을 호스팅하는 `UICollectionReusableView` 타입.
    ///
    /// 기본값은 ``ReusableViewType`` 을 `UIHostingController` 로 감싸는
    /// ``SwiftUIReusableView`` 입니다.
    associatedtype UIReusableViewType = SwiftUIReusableView<ReusableViewType>
}
