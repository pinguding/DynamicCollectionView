import Foundation

/// 아이템 레이아웃들을 선언형으로 모으는 result builder.
///
/// ``HGroupLayout``, ``VGroupLayout`` 의 `items` 클로저에 적용되어
/// 여러 ``ItemLayout`` 을 배열로 수집한다.
@resultBuilder
public struct ItemLayoutBuilder {
    /// 나열된 아이템 레이아웃들을 배열로 묶는다.
    ///
    /// - Parameter components: 빌더 본문에 나열된 아이템 레이아웃들.
    /// - Returns: 수집된 아이템 레이아웃 배열.
    public static func buildBlock(_ components: (any ItemLayout)...) -> [any ItemLayout] {
        components
    }

    /// `if` 분기의 참(첫 번째) 가지 결과를 전달한다.
    ///
    /// - Parameter component: 참 가지에서 만들어진 아이템 레이아웃 배열.
    /// - Returns: 전달된 아이템 레이아웃 배열.
    public static func buildEither(first component: [any ItemLayout]) -> [any ItemLayout] {
        component
    }

    /// `else` 분기의 거짓(두 번째) 가지 결과를 전달한다.
    ///
    /// - Parameter component: 거짓 가지에서 만들어진 아이템 레이아웃 배열.
    /// - Returns: 전달된 아이템 레이아웃 배열.
    public static func buildEither(second component: [any ItemLayout]) -> [any ItemLayout] {
        component
    }
}

/// 재사용 뷰(헤더/푸터) 레이아웃들을 선언형으로 모으는 result builder.
///
/// ``GridSectionLayout``, ``ListSectionLayout`` 의 `header`/`footer` 클로저에 적용되어
/// 여러 ``ReusableLayout`` 을 배열로 수집하며 옵셔널 분기를 지원한다.
@resultBuilder
public struct ReusableViewLayoutBuilder {
    /// 나열된 재사용 뷰 레이아웃들을 배열로 묶는다.
    ///
    /// - Parameter components: 빌더 본문에 나열된 재사용 뷰 레이아웃들.
    /// - Returns: 수집된 재사용 뷰 레이아웃 배열.
    public static func buildBlock(_ components: (any ReusableLayout)...) -> [any ReusableLayout] {
        components
    }

    /// `if` 분기의 참(첫 번째) 가지 결과를 전달한다.
    ///
    /// - Parameter component: 참 가지에서 만들어진 재사용 뷰 레이아웃 배열.
    /// - Returns: 전달된 재사용 뷰 레이아웃 배열.
    public static func buildEither(first component: [any ReusableLayout]) -> [any ReusableLayout] {
        component
    }

    /// `else` 분기의 거짓(두 번째) 가지 결과를 전달한다.
    ///
    /// - Parameter component: 거짓 가지에서 만들어진 재사용 뷰 레이아웃 배열.
    /// - Returns: 전달된 재사용 뷰 레이아웃 배열.
    public static func buildEither(second component: [any ReusableLayout]) -> [any ReusableLayout] {
        component
    }

    /// 단일 옵셔널 재사용 뷰 레이아웃을 처리한다.
    ///
    /// - Parameter component: 조건에 따라 존재하거나 없는 재사용 뷰 레이아웃.
    /// - Returns: 값이 있으면 이를 담은 배열, 없으면 빈 배열.
    public static func buildOptional(_ component: (any ReusableLayout)?) -> [any ReusableLayout] {
        if let component {
            return [component]
        } else {
            return []
        }
    }

    /// 옵셔널 재사용 뷰 레이아웃 배열을 처리한다.
    ///
    /// - Parameter components: 조건에 따라 존재하거나 없는 재사용 뷰 레이아웃 배열.
    /// - Returns: 값이 있으면 그 배열, 없으면 빈 배열.
    public static func buildOptional(_ components: [any ReusableLayout]?) -> [any ReusableLayout] {
        return components ?? []
    }
}
