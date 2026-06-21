import SwiftUI

/// SwiftUI ``CellView`` 를 `UICollectionViewCell` 위에 호스팅하는 브리지 셀.
///
/// 제네릭 파라미터 `View` 로 주어진 SwiftUI 셀 뷰를 `UIHostingController` 로 감싼 뒤
/// 셀의 `contentView` 에 오토레이아웃으로 가득 채워 배치합니다. UIKit 컬렉션 뷰
/// 인프라와 SwiftUI 선언형 뷰를 연결하는 역할을 합니다.
public final class SwiftUICell<View: CellView>: UICollectionViewCell, UICell {

    /// 이 셀이 호스팅하는 SwiftUI 뷰의 데이터 모델 타입.
    public typealias Model = View.Model

    private var model: Model?

    /// 셀이 재사용되기 전에 호스팅된 SwiftUI 뷰와 모델 참조를 정리합니다.
    override public func prepareForReuse() {
        super.prepareForReuse()

        self.contentView.subviews.forEach { $0.removeFromSuperview() }
        self.model = nil
    }

    /// 주어진 모델로 SwiftUI 셀 뷰를 생성해 셀에 호스팅합니다.
    ///
    /// 모델과 인덱스 경로로 ``CellView`` 를 만든 뒤 `UIHostingController` 로 감싸
    /// `contentView` 의 네 모서리에 제약을 걸어 가득 채웁니다.
    ///
    /// - Parameters:
    ///   - model: 셀이 표시할 데이터 모델.
    ///   - indexPath: 이 셀이 위치한 인덱스 경로.
    public func configure(model: Model, at indexPath: IndexPath) {
        self.model = model
        let cellView = View.init(model: model, indexPath: indexPath)
        let hostingViewController = UIHostingController(rootView: cellView)
        guard let hostingCellView = hostingViewController.view else {
            return
        }
        hostingCellView.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(hostingCellView)

        NSLayoutConstraint.activate([
            hostingCellView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            hostingCellView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            hostingCellView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            hostingCellView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }
}
