//import GoogleMaps
//import GoogleMapsUtils
//
//class CustomClusterRenderer: GMUDefaultClusterRenderer {
//    override func shouldRender(as cluster: GMUCluster, atZoom zoom: Float) -> Bool {
//        return zoom < 15.0
//    }
//
//    override func willRenderMarker(_ marker: GMSMarker) {
//        super.willRenderMarker(marker)
//        if let cluster = marker.userData as? GMUCluster {
//            let count = cluster.count
//            marker.icon = createClusterIcon(count: Int(count))
//        }
//    }
//
//    private func createClusterIcon(count: Int) -> UIImage? {
//        let diameter = CGFloat(40 + (count * 2))
//        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
//        return renderer.image { context in
//            UIColor.red.setFill()
//            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter)))
//            let attributes: [NSAttributedString.Key: Any] = [
//                .foregroundColor: UIColor.white,
//                .font: UIFont.boldSystemFont(ofSize: 20)
//            ]
//            let text = "\(count)"
//            let textSize = text.size(withAttributes: attributes)
//            let textRect = CGRect(
//                x: (diameter - textSize.width) / 2,
//                y: (diameter - textSize.height) / 2,
//                width: textSize.width,
//                height: textSize.height
//            )
//            text.draw(in: textRect, withAttributes: attributes)
//        }
//    }
//}
