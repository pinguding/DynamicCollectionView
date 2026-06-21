import Foundation

/// SwiftUI 기반 셀(``CellView``)을 구성하기 위한 데이터 모델 프로토콜.
///
/// `UICellConfigurableModel` 을 상속하여, 모델이 어떤 SwiftUI 셀 뷰와 그 셀을
/// 호스팅하는 `UICollectionViewCell` 타입에 매핑되는지를 연관타입으로 선언합니다.
///
/// - Note: 이 프로토콜은 `ObservableObject` 채택을 요구하지 않습니다. 셀 내부에서
///   값 변화를 관찰해야 할 때에만 모델 타입이 직접 `ObservableObject` 를 채택하면
///   됩니다.
public protocol CellViewConfigurableModel: UICellConfigurableModel {

    /// 이 모델로 구성되는 SwiftUI 셀 뷰의 타입.
    associatedtype CellViewType: CellView

    /// 모델을 호스팅하는 `UICollectionViewCell` 타입.
    ///
    /// 기본값은 ``CellViewType`` 을 `UIHostingController` 로 감싸는
    /// ``SwiftUICell`` 입니다.
    associatedtype CellType = SwiftUICell<CellViewType>
}

/// 셀이 차지하는 크기 비율을 직접 지정할 수 있는 ``CellViewConfigurableModel``.
///
/// 표준 레이아웃 대신 너비/높이 비율을 모델에서 제어하고 싶을 때 채택합니다.
public protocol CustomLayoutCellViewConfigurableModel: CellViewConfigurableModel {

    /// 셀이 레이아웃에서 차지할 크기 비율.
    var sizeRatio: CGFloat { get }
}
