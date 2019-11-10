import SwiftUI
import MapKit
import DVB

struct MapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D

    func makeUIView(context: UIViewRepresentableContext<MapView>) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false

        let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: 1_000, pitch: 0.45, heading: 0.5)
        mapView.camera = camera

        mapView.mapType = .mutedStandard

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MapView>) {}
}

final class RouteMapView: NSObject, UIViewRepresentable {
    var route: Route

    init(route: Route) {
        self.route = route
        super.init()
    }

    func makeUIView(context: UIViewRepresentableContext<RouteMapView>) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = self
//        mapView.isUserInteractionEnabled = false

        mapView.mapType = .mutedStandard

        let mapPoints = route.mapData.flatMap { $0.points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }}
        let polyline = MKPolyline(coordinates: mapPoints, count: mapPoints.count)
        mapView.addOverlay(polyline)

        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), animated: false)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<RouteMapView>) {}
}

extension RouteMapView: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRenderer = MKPolylineRenderer(overlay: overlay)
        lineRenderer.strokeColor = .red
        lineRenderer.lineWidth = 5
        return lineRenderer
    }
}
