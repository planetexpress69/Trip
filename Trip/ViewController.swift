//
//  ViewController.swift
//  Trip
//
//  Created by Martin Kautz on 13.10.16.
//
//

import Cocoa
import MapKit

open class ViewController: NSViewController, MKMapViewDelegate {

    @IBOutlet weak var numberOfTrackpointsField: NSTextField?
    @IBOutlet weak var distanceField: NSTextField?
    @IBOutlet weak var maxSpeedField: NSTextField?
    @IBOutlet weak var fullDurationField: NSTextField?
    @IBOutlet weak var movingDurationField: NSTextField?
    @IBOutlet weak var statusField: NSTextField?
    @IBOutlet weak var spinner: NSProgressIndicator?
    @IBOutlet weak var mapView: MKMapView?

    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        spinner?.minValue = 0
        spinner?.maxValue = 100
        spinner?.usesThreadedAnimation = true
        statusField?.stringValue = ""
        mapView?.delegate = self

    }

    override open var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    public func setProgress(progress: Double) {
        spinner?.increment(by: progress )
    }

    public func setMaxSpeed(speed: Double) {
        maxSpeedField?.stringValue = "\(speed) knots"
    }

    public func setMovingDuration(duration: Double) {
        movingDurationField?.stringValue = "\(duration) hours"
    }

    public func setFullDuration(duration: Double) {
        fullDurationField?.stringValue = "\(duration) hours"
    }

    public func setDistance(distance: Double) {
        distanceField?.stringValue = "\(distance) nm"
    }

    public func setProcessedPoints(points: Int) {
        numberOfTrackpointsField?.stringValue = "\(points)"
    }

    public func resetSpinner() {
        spinner?.increment(by: -((spinner?.doubleValue)!))
    }

    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var identifier = "TrackpointLow"

        if annotation is Trackpoint {

            var speed = 0.0

            if let a = annotation as? Trackpoint {
                if (a.exposedSpeed() > 6.9) {
                    identifier = "TrackpointHigh"
                    print (a.exposedSpeed())
                }
                speed = a.exposedSpeed()
            }



            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                annotationView.annotation = annotation
                return annotationView
            } else {
                let annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier:identifier)
                annotationView.isEnabled = true
                annotationView.canShowCallout = true
                annotationView.pinTintColor = speed > 6.9 ? .red : NSColor.init(red: 128/255, green: 255, blue: 255, alpha: 1)

                //let btn = UIButton(type: .detailDisclosure)
                //annotationView.rightCalloutAccessoryView = btn
                return annotationView
            }
        }
        
        return nil
    }
}
