//
//  ViewController.swift
//  Trip
//
//  Created by Martin Kautz on 13.10.16.
//
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var numberOfTrackpointsField: NSTextField?
    @IBOutlet weak var distanceField: NSTextField?
    @IBOutlet weak var maxSpeedField: NSTextField?


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(self.showData), name: NSNotification.Name(rawValue: "DidGetData"), object:nil)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func showData(notification: NSNotification) -> () {
        let dict = notification.object as! NSDictionary
        let numOfPos = dict["numOfPos"]
        let completeDistance = dict["completeDistance"]
        let maxSpeed = dict["maxSpeed"]
        numberOfTrackpointsField?.stringValue = "\(numOfPos as! String)"
        distanceField?.stringValue = "\(completeDistance as! String) nm"
        maxSpeedField?.stringValue = "\(maxSpeed as! String) knots"
    }

}
