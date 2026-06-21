import SwiftUI

/// 서플먼터리 뷰(헤더/푸터)의 종류를 나타내는 열거형.
///
/// 각 케이스는 UIKit 의 서플먼터리 엘리먼트 종류 문자열
/// (`UICollectionView.elementKindSectionHeader` / `Footer`)에 매핑됩니다.
public enum ReusableViewElementKind: String {
    /// 섹션 헤더 서플먼터리 뷰.
    case header
    /// 섹션 푸터 서플먼터리 뷰.
    case footer

    /// 케이스에 대응하는 UIKit 서플먼터리 엘리먼트 종류 문자열.
    public var rawValue: String {
        switch self {
        case .header:
            return UICollectionView.elementKindSectionHeader
        case .footer:
            return UICollectionView.elementKindSectionFooter
        }
    }
}

/// 컬렉션 뷰의 서플먼터리 뷰(헤더/푸터)로 렌더링되는 SwiftUI 뷰가 채택하는 프로토콜.
///
/// ``CellView`` 와 유사하게, 이 프로토콜을 채택한 SwiftUI `View` 는
/// ``SwiftUIReusableView`` 브리지를 통해 `UICollectionReusableView` 위에
/// 호스팅됩니다. 연관타입 ``Model`` 과 ``elementKind`` 로 어떤 데이터를 어떤
/// 위치(헤더/푸터)에 표시할지 선언합니다.
public protocol ReusableView: View {

    /// 이 서플먼터리 뷰가 표시할 데이터 모델의 타입.
    associatedtype Model: ReusableViewConfigurableModel

    /// 이 뷰가 헤더인지 푸터인지를 나타내는 서플먼터리 엘리먼트 종류.
    static var elementKind: ReusableViewElementKind { get }

    /// 주어진 모델과 인덱스 경로로 서플먼터리 뷰를 생성합니다.
    ///
    /// - Parameters:
    ///   - model: 뷰가 표시할 데이터 모델.
    ///   - indexPath: 이 뷰가 위치한 컬렉션 뷰의 인덱스 경로.
    init(model: Model, indexPath: IndexPath)
}
