import SwiftUI

/// SwiftUI ``ReusableView`` 를 `UICollectionReusableView` 위에 호스팅하는 브리지 뷰.
///
/// 제네릭 파라미터 `View` 로 주어진 SwiftUI 서플먼터리 뷰를 `UIHostingController`
/// 로 감싸 헤더/푸터 자리에 배치합니다. 호스팅 컨트롤러를 부모 뷰 컨트롤러에 자식으로
/// 연결(attach)해 라이프사이클을 관리하고, ``preferredLayoutAttributesFitting(_:)``
/// 에서 계산한 크기를 모델 식별자별로 캐시하여 반복 레이아웃 비용을 줄입니다.
public final class SwiftUIReusableView<View: ReusableView>: UICollectionReusableView, UIReusableView {

    /// 이 뷰가 호스팅하는 SwiftUI 뷰의 데이터 모델 타입.
    public typealias Model = View.Model

    /// 이 서플먼터리 뷰의 엘리먼트 종류 문자열(헤더/푸터).
    public static var elementKind: String {
        View.elementKind.rawValue
    }

    private var model: Model?

    private weak var hostingViewController: UIViewController?

    private var cachedSize: [String: CGSize] = [:]

    /// 뷰가 재사용되기 전에 호스팅 컨트롤러를 부모에서 분리하고 참조를 정리합니다.
    override public func prepareForReuse() {
        super.prepareForReuse()

        self.detachParent(self.hostingViewController)
        self.hostingViewController = nil
        self.model = nil
    }

    /// 서플먼터리 뷰에 맞는 레이아웃 속성을 계산하고, 모델별 크기를 캐시합니다.
    ///
    /// 동일 모델에 대해 이미 계산된 크기가 캐시에 있으면 그 값을 재사용하고,
    /// 없으면 상위 구현으로 크기를 계산해 모델 식별자(`model.id`)를 키로 캐시합니다.
    ///
    /// - Parameter layoutAttributes: 컬렉션 뷰가 제안한 레이아웃 속성.
    /// - Returns: 콘텐츠 크기가 반영된 레이아웃 속성.
    override public func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {

        guard let model else {
            return super.preferredLayoutAttributesFitting(layoutAttributes)
        }

        if let cachedSize =  self.cachedSize[model.id] {
            layoutAttributes.size = cachedSize
            return layoutAttributes
        } else {
            let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
            let size = attributes.size
            layoutAttributes.size = size
            self.cachedSize[model.id] = size
            return attributes
        }
    }

    /// 주어진 모델로 SwiftUI 서플먼터리 뷰를 생성해 호스팅합니다.
    ///
    /// 모델과 인덱스 경로로 ``ReusableView`` 를 만들어 `UIHostingController` 로 감싼 뒤
    /// 뷰의 네 모서리에 제약을 걸어 가득 채우고, 호스팅 컨트롤러를 부모 뷰 컨트롤러의
    /// 자식으로 연결합니다.
    ///
    /// - Parameters:
    ///   - model: 뷰가 표시할 데이터 모델.
    ///   - indexPath: 이 뷰가 위치한 인덱스 경로.
    public func configure(model: Model, at indexPath: IndexPath) {
        self.model = model
        let cellView = View.init(model: model, indexPath: indexPath)
        let hostingViewController = UIHostingController(rootView: cellView)
        guard let hostingCellView = hostingViewController.view else {
            return
        }
        self.hostingViewController = hostingViewController
        hostingCellView.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(hostingCellView)

        self.attachParent(self.parentViewController(), childViewController: hostingViewController)

        NSLayoutConstraint.activate([
            hostingCellView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hostingCellView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            hostingCellView.topAnchor.constraint(equalTo: self.topAnchor),
            hostingCellView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    /// 호스팅 컨트롤러를 부모 뷰 컨트롤러의 자식으로 연결합니다.
    ///
    /// - Parameters:
    ///   - parentViewController: 자식으로 추가될 부모 뷰 컨트롤러. `nil` 이면 아무 작업도 하지 않습니다.
    ///   - childViewController: 부모에 연결할 호스팅 컨트롤러.
    private func attachParent(_ parentViewController: UIViewController?, childViewController: UIViewController) {
        guard let parentViewController else { return }
        parentViewController.addChild(childViewController)
        childViewController.didMove(toParent: parentViewController)
    }

    /// 호스팅 컨트롤러를 부모에서 분리하고 뷰와 제약을 정리합니다.
    ///
    /// - Parameter childViewController: 분리할 호스팅 컨트롤러.
    private func detachParent(_ childViewController: UIViewController?) {
        childViewController?.removeFromParent()
        childViewController?.view.removeConstraints(childViewController?.view.constraints ?? [])
        childViewController?.view.removeFromSuperview()
    }

    /// 책임자 체인을 따라 올라가며 이 뷰를 포함하는 가장 가까운 뷰 컨트롤러를 찾습니다.
    ///
    /// - Returns: 찾은 뷰 컨트롤러, 없으면 `nil`.
    private func parentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let currentResponder = responder {
            if let viewController = currentResponder as? UIViewController {
                return viewController
            }
            responder = currentResponder.next
        }
        return nil
    }
}
