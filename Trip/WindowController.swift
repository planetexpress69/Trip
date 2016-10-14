//
//  WindowController.swift
//  Trip
//
//  Created by Martin Kautz on 13.10.16.
//
//

import Cocoa
import AEXML


class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }


    // ---------------------------------------------------------------------------------------------
    // MARK: - User triggered actions
    // ---------------------------------------------------------------------------------------------
    @IBAction func openGPXFile(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["GPX", "gpx"]

        openPanel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self._load(openPanel.url!)
            }
        }
    }

    // ---------------------------------------------------------------------------------------------
    // MARK: Load XML
    // ---------------------------------------------------------------------------------------------
    func _load(_ url: URL) {

        let viewController = (self.window?.contentViewController) as! ViewController
        viewController.startSpinner()

        //viewController.startSpinner();

        DispatchQueue.global().async {

            guard let
                data = try? Data(contentsOf: url)
            else {
                return
            }
            do {
                let xmlDoc = try AEXMLDocument(xml: data)
                var prevLat:Double = 0.0
                var prevLon:Double = 0.0
                var prevTime: Date = Date()
                var completeDistance:Double = 0.0
                var maxSpeed: Double = 0.0
                var timeOfMaxSpeed: Date = Date()
                var prevTimeOfMaxSpeed: Date = Date()
                let infinity = Double.infinity
                var i = 0
                var tick = 1;
                for item in xmlDoc.root["trk"].children {
                    if item.name == "trkseg" {
                        for pos in item.children {
                            tick = tick + 1
                            // pyramid of doom! \o/
                            if (tick % 15 == 0) {
                                if let lat = pos.attributes["lat"]  {
                                    if let lon = pos.attributes["lon"]  {
                                        if let time = pos.children[0].value {
                                            if let datetime = self.stringToDate(sDate: time) {
                                                if prevLat != 0.0 {
                                                    let distance = (self.haversineDinstance(la1: prevLat, lo1: prevLon, la2: lat.doubleValue, lo2: lon.doubleValue))
                                                    completeDistance += distance
                                                    let diff = (datetime.timeIntervalSince(prevTime))
                                                    let speed = (distance / diff * 3.6 / 1.852)
                                                    if speed < infinity && speed > maxSpeed {
                                                        timeOfMaxSpeed = datetime
                                                        prevTimeOfMaxSpeed = prevTime
                                                        maxSpeed = speed
                                                    }
                                                }
                                                prevLat = lat.doubleValue
                                                prevLon = lon.doubleValue
                                                prevTime = datetime
                                            }
                                        }
                                    }
                                }
                                i = i + 1;
                            }
                        }
                    }
                }

                DispatchQueue.main.async {

                    viewController.stopSpinner()

                    print("Number of pos: \(i)")
                    print("Distance     : \(completeDistance / 1000 / 1.852) nm")
                    print("Max speed    : \(maxSpeed) knots @ \(prevTimeOfMaxSpeed) - \(timeOfMaxSpeed)")

                    let result: [String:String] = [
                        "numOfPos": String(i),
                        "completeDistance": String((completeDistance / 1000 / 1.852).roundTo(places: 3)),
                        "maxSpeed": String(maxSpeed.roundTo(places: 3))
                    ]

                    NotificationCenter.default.post(name: Notification.Name(rawValue: "DidGetData"), object: result, userInfo: nil);
                }
            }
            catch {
                print("\(error)")
            }
        }
    }

    func stringToDate(sDate:String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.date(from: sDate)
    }

    func haversineDinstance(la1: Double, lo1: Double, la2: Double, lo2: Double, radius: Double = 6367444.7) -> Double {

        let haversin = { (angle: Double) -> Double in
            return (1 - cos(angle))/2
        }

        let ahaversin = { (angle: Double) -> Double in
            return 2*asin(sqrt(angle))
        }
        
        // Converts from degrees to radians
        let dToR = { (angle: Double) -> Double in
            return (angle / 360) * 2 * M_PI
        }
        
        let lat1 = dToR(la1)
        let lon1 = dToR(lo1)
        let lat2 = dToR(la2)
        let lon2 = dToR(lo2)
        
        return radius * ahaversin(haversin(lat2 - lat1) + cos(lat1) * cos(lat2) * haversin(lon2 - lon1))
    }
}

extension String {
    var doubleValue: Double {
        return (self as NSString).doubleValue
    }
}

extension Double {
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
