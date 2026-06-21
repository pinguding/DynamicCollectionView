import Foundation

extension Array {
    /// 범위를 벗어난 인덱스로 접근해도 크래시하지 않고 안전하게 요소를 반환하는 서브스크립트.
    ///
    /// 일반 첨자 접근과 달리, 유효 범위(`indices`)를 벗어난 인덱스가 주어지면
    /// 프로그램을 중단시키는 대신 `nil` 을 반환합니다. 컬렉션 뷰처럼 인덱스가
    /// 비동기로 변경될 수 있어 경계 검사가 필요한 곳에서 크래시를 방지하기 위한
    /// 라이브러리 내부 헬퍼입니다.
    ///
    /// - Parameter index: 접근할 요소의 인덱스.
    /// - Returns: `index` 가 유효 범위 안이면 해당 요소, 범위를 벗어나면 `nil`.
    subscript(safe index: Int) -> Element? {
        indices ~= index ? self[index] : nil
    }
}
