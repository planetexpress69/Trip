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

        let strt = Date()

        let viewController = (self.window?.contentViewController) as! ViewController
        viewController.setProgress(progress: 1)
        viewController.resetSpinner()

        DispatchQueue.global().async {

            guard let data = try? Data(contentsOf: url) else {
                return
            }
            do {
                let xmlDoc = try AEXMLDocument(xml: data)

                // memorize
                var prevLat:Double = 0.0
                var prevLon:Double = 0.0
                var prevTime: Date = Date()
                var prevTimeOfMaxSpeed: Date = Date()

                // 20 seconds
                var time20: Date = Date()
                var lat20: Double = 0.0
                var lon20: Double = 0.0

                // two minutes
                var time120: Date = Date()
                var lat120: Double = 0.0
                var lon120: Double = 0.0

                // results
                var fullDistance:Double = 0.0
                var maxSpeed: Double = 0.0
                var timeOfMaxSpeed: Date = Date()
                var fullDuration: Double = 0.0
                var movingDuration: Double = 0.0

                // define infinity
                let infinity = Double.infinity

                // ticker, counter, percent
                var i = 0
                var tick = 1
                var savedPercent = 0

                // check how many points we need to calculate
                var numberoftrkpts = 0
                for item in xmlDoc.root["trk"].children {
                    if item.name == "trkseg" {
                        numberoftrkpts += item.children.count
                    }
                }

                // loop trkseg
                for item in xmlDoc.root["trk"].children {
                    if item.name == "trkseg" {
                        // loop trkpts
                        for pos in item.children {

                            tick = tick + 1

                            let percent = 100 * tick / numberoftrkpts
                            if (percent > savedPercent) {
                                DispatchQueue.main.async {
                                    viewController.setProgress(progress: 1)
                                }
                                savedPercent = percent
                            }

                            guard
                                let lat = pos.attributes["lat"],
                                let lon = pos.attributes["lon"],
                                let time = pos.children[0].value ,
                                let datetime = self.stringToDate(sDate: time) else {
                                    return
                            }

                            // first round - so memorize some stuff
                            if i == 0 {
                                time20 = datetime
                                lat20 = lat.doubleValue
                                lon20 = lon.doubleValue

                                time120 = datetime
                                lat120 = lat.doubleValue
                                lon120 = lon.doubleValue
                            }

                            // calculate speed on 20 second slices
                            if datetime.timeIntervalSince(time20) > 20 {

                                let averageDistance20 = (self.haversineDinstance(la1: lat20, lo1: lon20, la2: lat.doubleValue, lo2: lon.doubleValue))
                                let speed20 = (averageDistance20 / datetime.timeIntervalSince(time20) * 3.6 / 1.852)

                                if speed20 < infinity && speed20 > maxSpeed {
                                    maxSpeed = speed20
                                }
                                timeOfMaxSpeed = datetime
                                prevTimeOfMaxSpeed = time20

                                lat20 = lat.doubleValue
                                lon20 = lon.doubleValue
                                time20 = datetime
                            }

                            // try to detect moving (rather tricky) and increment actual moving time
                            else if datetime.timeIntervalSince(time120) > 300 {

                                let averageDistance120 = (self.haversineDinstance(la1: lat120, lo1: lon120, la2: lat.doubleValue, lo2: lon.doubleValue))
                                let speed120 = (averageDistance120 / datetime.timeIntervalSince(time120) * 3.6 / 1.852)
                                if speed120 > 3.0 { // ASSUMPTION BASED ON MEMORIES
                                    movingDuration += datetime.timeIntervalSince(time120)

                                    DispatchQueue.main.async {
                                        viewController.setMovingDuration(duration: (movingDuration / 60 / 60).roundTo(places: 3))
                                        viewController.setFullDuration(duration: (fullDuration / 60 / 60).roundTo(places: 3))
                                        viewController.setMaxSpeed(speed: maxSpeed.roundTo(places: 3))
                                        viewController.setDistance(distance: (fullDistance / 1000 / 1.852).roundTo(places: 3))
                                        viewController.setProcessedPoints(points: i)
                                    }
                                } else {

                                }

                                lat120 = lat.doubleValue
                                lon120 = lon.doubleValue
                                time120 = datetime
                            }

                            // calculate distance to previous trackpoint and add to full distance
                            // same to duration :-)
                            if prevLat != 0.0 { // skip the first record as it has no predecessor to do the math with
                                let distance = (self.haversineDinstance(la1: prevLat, lo1: prevLon, la2: lat.doubleValue, lo2: lon.doubleValue))
                                fullDistance += distance
                                let diff = (datetime.timeIntervalSince(prevTime))
                                if (diff > 60.0) {
                                    print("Gap of \(diff) seconds at \(prevTime) to \(datetime) Dist: \(distance) >>> \(distance / diff)")
                                }
                                fullDuration += diff
                            }

                            prevLat = lat.doubleValue
                            prevLon = lon.doubleValue
                            prevTime = datetime
                            i = i + 1
                        }
                    }
                }

                DispatchQueue.main.async {

                    print("Number of pos    : \(i)")
                    print("Distance         : \(fullDistance / 1000 / 1.852) nm")
                    print("Max speed        : \(maxSpeed) knots @ \(prevTimeOfMaxSpeed) - \(timeOfMaxSpeed)")
                    print("Full duration    : \(fullDuration / 60 / 60) hours")
                    print("Moving duration  : \(movingDuration / 60 / 60) hours")

                    let end = Date()
                    print ("Duration of reading, parsing and calculation: \(end.timeIntervalSince(strt))")

                }
            }
            catch {
                print("\(error)")
            }
        } // end async
    }

    func stringToDate(sDate:String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
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
