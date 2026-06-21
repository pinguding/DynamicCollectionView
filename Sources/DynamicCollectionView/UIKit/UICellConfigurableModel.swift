import UIKit

/// ``UIDynamicCollectionView``에서 ``UICell``을 디큐(dequeue)하고 구성하는 데 사용되는 모델 프로토콜.
///
/// 연관 타입 ``CellType``을 통해 모델과 셀을 1:1로 연결한다. 클래스(`AnyObject`)
/// 기반이므로 참조 의미를 가지며, ``UIDynamicCollectionView``가 모델로부터 적절한
/// 셀을 만들어 내는 진입점이 된다.
///
/// - Note: 이 프로토콜은 의도적으로 `@MainActor`로 격리하지 않는다.
///   Reactor/ViewModel이 백그라운드 스레드에서 섹션과 모델을 조립할 수 있게
///   하기 위함이며, 스레드 안전성은 "백그라운드 조립 → 메인으로 전달 →
///   메인에서 apply" 흐름으로 확보한다.
public protocol UICellConfigurableModel: AnyObject {

    /// 이 모델과 매칭되는 셀 타입.
    associatedtype CellType: UICell

    /// `UICollectionViewDiffableDataSource`에서 아이템 식별자로 사용될 값.
    var id: String { get }

    /// 디큐된 셀을 ``CellType``으로 캐스팅하고 이 모델로 구성하여 반환한다.
    ///
    /// - Parameters:
    ///   - dequeuedCell: CollectionView로부터 디큐된 셀.
    ///   - indexPath: 셀이 위치하는 인덱스 패스.
    /// - Returns: 구성에 성공한 ``CellType`` 셀. 캐스팅에 실패하면 `nil`.
    func configuredCell(_ dequeuedCell: UICollectionViewCell, at indexPath: IndexPath) -> CellType?
}

public extension UICellConfigurableModel {

    /// 디큐된 셀과 자기 자신을 각각 ``CellType``과 그 모델 타입으로 캐스팅한 뒤
    /// `configure(model:at:)`를 호출해 셀을 구성하는 기본 구현.
    ///
    /// - Parameters:
    ///   - dequeuedCell: CollectionView로부터 디큐된 셀.
    ///   - indexPath: 셀이 위치하는 인덱스 패스.
    /// - Returns: 구성된 셀. 셀 또는 모델 캐스팅에 실패하면 `nil`.
    func configuredCell(_ dequeuedCell: UICollectionViewCell, at indexPath: IndexPath) -> CellType? {
        guard let cell = dequeuedCell as? CellType,
              let transformedModel = self as? Self.CellType.Model
        else { return nil }

        cell.configure(model: transformedModel, at: indexPath)

        return cell
    }
}
