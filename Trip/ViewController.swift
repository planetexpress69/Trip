//
//  ViewController.swift
//  Trip
//
//  Created by Martin Kautz on 13.10.16.
//
//

import Cocoa

open class ViewController: NSViewController {

    @IBOutlet weak var numberOfTrackpointsField: NSTextField?
    @IBOutlet weak var distanceField: NSTextField?
    @IBOutlet weak var maxSpeedField: NSTextField?
    @IBOutlet weak var fullDurationField: NSTextField?
    @IBOutlet weak var movingDurationField: NSTextField?
    @IBOutlet weak var statusField: NSTextField?
    @IBOutlet weak var spinner: NSProgressIndicator?

    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        spinner?.minValue = 0
        spinner?.maxValue = 100
        spinner?.usesThreadedAnimation = true
        statusField?.stringValue = ""

        self.title = "Trip"
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
}
