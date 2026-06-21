import Foundation

/// 타입 스스로를 식별하는 문자열을 제공하는 프로토콜.
///
/// 셀이나 재사용 뷰처럼 객체 타입별로 고유한 재사용 식별자(reuse identifier)가
/// 필요한 경우에 사용한다. 기본 구현이 제공되므로 채택만 하면 별도 구현 없이
/// 타입 이름을 식별자로 사용할 수 있다.
public protocol SelfIdentifiable {

    /// 해당 타입을 식별하는 문자열.
    ///
    /// CollectionView에 컴포넌트를 등록하거나 디큐(dequeue)할 때
    /// 재사용 식별자로 사용된다.
    static var selfIdentifier: String { get }
}

public extension SelfIdentifiable {

    /// `String(describing:)`로 타입 이름을 만들어 반환하는 기본 구현.
    static var selfIdentifier: String {
        String(describing: Self.self)
    }
}
