import UIKit

class MainViewController: UIViewController, UIScrollViewDelegate {

    var scrollView: UIScrollView!
    var pageControl: UIPageControl!
    var images: [UIImage] = []
    var currentPageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // 이미지 배열 설정
        images = [UIImage(named: "image1")!, UIImage(named: "image2")!, UIImage(named: "image3")!]

        setupScrollView(images: images)
        setupPageControl(numberOfPages: images.count)
        setupCurrentPageLabel()
    }

    func setupScrollView(images: [UIImage]) {
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 200))
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(images.count), height: 200)
        scrollView.showsHorizontalScrollIndicator = false

        for (index, image) in images.enumerated() {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.frame = CGRect(x: view.frame.width * CGFloat(index), y: 0, width: view.frame.width, height: 200)
            imageView.clipsToBounds = true
            scrollView.addSubview(imageView)
        }

        view.addSubview(scrollView)
    }


    func setupPageControl(numberOfPages: Int) {
        pageControl = UIPageControl(frame: CGRect(x: 0, y: 300, width: view.frame.width, height: 20))
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = 0
        pageControl.tintColor = .red
        pageControl.pageIndicatorTintColor = .gray
        pageControl.currentPageIndicatorTintColor = .red
        view.addSubview(pageControl)
    }

    func setupCurrentPageLabel() {
        currentPageLabel = UILabel(frame: CGRect(x: 0, y: 320, width: view.frame.width, height: 20))
        currentPageLabel.textAlignment = .center
        currentPageLabel.text = "1/\(images.count)"
        view.addSubview(currentPageLabel)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
        pageControl.currentPage = Int(pageIndex)
        currentPageLabel.text = "\(pageControl.currentPage + 1)/\(pageControl.numberOfPages)"
    }
}
