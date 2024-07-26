import UIKit

class LoadingIndicatorManager {
    static let shared = LoadingIndicatorManager()
    private var spinner: UIActivityIndicatorView?

    private init() {}

    func show(in view: UIView) {
        DispatchQueue.main.async {
            self.spinner = UIActivityIndicatorView(style: .large)
            self.spinner?.center = view.center
            self.spinner?.hidesWhenStopped = true
            view.addSubview(self.spinner!)
            self.spinner?.startAnimating()
        }
    }

    func hide() {
        DispatchQueue.main.async {
            self.spinner?.stopAnimating()
            self.spinner?.removeFromSuperview()
            self.spinner = nil
        }
    }
}
