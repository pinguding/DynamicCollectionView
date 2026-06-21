import SwiftUI

/// 컬렉션 뷰의 셀로 렌더링되는 SwiftUI 뷰가 채택하는 프로토콜.
///
/// 이 프로토콜을 채택한 SwiftUI `View` 는 ``SwiftUICell`` 브리지를 통해
/// `UICollectionViewCell` 위에 호스팅됩니다. 연관타입 ``Model`` 로 셀이 표시할
/// 데이터의 타입을 선언하고, 모델과 인덱스 경로를 받는 이니셜라이저로 셀의
/// 콘텐츠를 구성합니다.
public protocol CellView: View {
    /// 이 셀 뷰가 표시할 데이터 모델의 타입.
    ///
    /// ``CellViewConfigurableModel`` 을 채택한 타입이어야 하며, 셀과 모델을
    /// 서로 연결하는 역할을 합니다.
    associatedtype Model: CellViewConfigurableModel

    /// 주어진 모델과 인덱스 경로로 셀 뷰를 생성합니다.
    ///
    /// - Parameters:
    ///   - model: 셀이 표시할 데이터 모델.
    ///   - indexPath: 이 셀이 위치한 컬렉션 뷰의 인덱스 경로.
    init(model: Model, indexPath: IndexPath)
}
