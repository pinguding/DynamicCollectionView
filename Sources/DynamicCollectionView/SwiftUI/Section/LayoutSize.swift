import UIKit

/// 레이아웃 치수를 표현하는 열거형.
///
/// `NSCollectionLayoutDimension` 으로 매핑되며, 너비/높이 지정에 사용된다.
public enum LayoutSize {
    /// 컨테이너 너비에 대한 비율(0~1)로 지정하는 치수.
    case fractionalWidth(CGFloat)
    /// 컨테이너 높이에 대한 비율(0~1)로 지정하는 치수.
    case fractionalHeight(CGFloat)
    /// 추정값으로 지정하는 치수. 실제 콘텐츠에 따라 자동 조정된다.
    case estimated(CGFloat)
    /// 포인트 단위 고정값으로 지정하는 치수.
    case absolute(CGFloat)
}

extension LayoutSize {
    /// 대응하는 `NSCollectionLayoutDimension` 으로 변환한 값.
    var nsCollectionLayoutDimension: NSCollectionLayoutDimension {
        switch self {
        case let .fractionalWidth(value):
            return .fractionalWidth(value)
        case let .fractionalHeight(value):
            return .fractionalHeight(value)
        case let .estimated(value):
            return .estimated(value)
        case let .absolute(value):
            return .absolute(value)
        }
    }
}
