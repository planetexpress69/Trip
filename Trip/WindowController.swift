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


    // ---------------------------------------------------------------------------------------------
    // MARK: Lifecycle
    // ---------------------------------------------------------------------------------------------
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.minSize = NSSize(width: 600.0, height: 242.0)

    }


    // ---------------------------------------------------------------------------------------------
    // MARK: User triggered actions
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

        self.window?.title = url.relativeString


        let strt = Date()

        let viewController = (self.window?.contentViewController) as! ViewController
        viewController.setProgress(progress: 1)
        viewController.resetSpinner()
        viewController.statusField?.stringValue = "Loading file"
        //var annotations = [Trackpoint]()

        DispatchQueue.global().async { [weak self]
            () -> Void in

            guard let data = try? Data(contentsOf: url) else {
                return
            }
            do {
                DispatchQueue.main.async {
                    () -> Void in
                    viewController.statusField?.stringValue = "File loaded. Parsing XML now..."
                }

                let xmlDoc = try AEXMLDocument(xml: data)
                DispatchQueue.main.async {
                    () -> Void in
                    viewController.statusField?.stringValue = "Parsing done. Analyzing track..."
                }


                // memorize
                var prevLat = 0.0
                var prevLon = 0.0
                var prevTime = Date()
                //var prevTimeOfMaxSpeed: Date = Date()

                // 20 seconds
                var time20 = Date()
                var lat20 = 0.0
                var lon20 = 0.0

                // two minutes
                var time120 = Date()
                var lat120 = 0.0
                var lon120 = 0.0

                // results
                var fullDistance = 0.0
                var maxSpeed = 0.0
                //var timeOfMaxSpeed: Date = Date()
                var fullDuration = 0.0
                var movingDuration = 0.0

                // define infinity
                let infinity = Double.infinity

                // ticker, counter, percent
                var i = 0
                var tick = 1
                var savedPercent = 0

                // top left
                var largestLat = 0.0
                var smallestLon = 0.0

                // bottom right
                var smallestLat = 0.0
                var largestLon = 0.0


                // check how many points we need to calculate


                var numberoftrkpts = 0
                for item in xmlDoc.root["trk"].children {
                   if item.name == "trkseg" {
                        numberoftrkpts += item.children.count
                    }
                }

                DispatchQueue.main.async {
                    () -> Void in
                    viewController.statusField?.stringValue = "Analyzing done. Doing the math..."
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
                                    () -> Void in
                                    viewController.setProgress(progress: 1)
                                }
                                savedPercent = percent
                            }

                            guard
                                let lat = pos.attributes["lat"],
                                let lon = pos.attributes["lon"],
                                let time = pos.children[0].value ,
                                let datetime = self?.stringToDate(sDate: time) else {
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

                                largestLat = lat.doubleValue
                                smallestLon = lon.doubleValue

                                smallestLat = lat.doubleValue
                                largestLon = lon.doubleValue
                            }

                            if (i > 0) {
                                if (lat.doubleValue < smallestLat) {
                                    smallestLat = lat.doubleValue
                                }
                                if (lon.doubleValue < smallestLon) {
                                    smallestLon = lon.doubleValue
                                }
                                if (lat.doubleValue > largestLat) {
                                    largestLat = lat.doubleValue
                                }
                                if (lon.doubleValue > largestLon) {
                                    largestLon = lon.doubleValue
                                }
                            }

                            // calculate speed on 20 second slices
                            if datetime.timeIntervalSince(time20) > 20 {

                                let averageDistance20 = (self?.haversineDinstance(la1: lat20, lo1: lon20, la2: lat.doubleValue, lo2: lon.doubleValue))
                                let speed20 = (averageDistance20! / datetime.timeIntervalSince(time20) * 3.6 / 1.852)

                                if speed20 < infinity && speed20 > maxSpeed {
                                    maxSpeed = speed20
                                    if (maxSpeed > 8.0) {

                                        let trackpoint = Trackpoint.init(latitude: lat.doubleValue, longitude: lon.doubleValue)
                                        if let s = self?.dateToString(date: datetime) {
                                            trackpoint.title = "\(s) @ \(speed20.roundTo(places: 2)) knots"
                                            trackpoint.speed = speed20.roundTo(places: 2)
                                            trackpoint.subtitle = "\((movingDuration / 60 / 60).roundTo(places: 2)) hours"
                                        }
                                        DispatchQueue.main.async { [weak self]
                                            () -> Void in
                                            viewController.mapView?.addAnnotation(trackpoint)
                                        }
                                    }
                                    //currSpeed = speed20
                                }
                                //timeOfMaxSpeed = datetime
                                //prevTimeOfMaxSpeed = time20


                                lat20 = lat.doubleValue
                                lon20 = lon.doubleValue
                                time20 = datetime



                            }
                            // try to detect moving (rather tricky) and increment actual moving time
                            else if datetime.timeIntervalSince(time120) > 300 {

                                let averageDistance120 = (self?.haversineDinstance(la1: lat120, lo1: lon120, la2: lat.doubleValue, lo2: lon.doubleValue))
                                let speed120 = (averageDistance120! / datetime.timeIntervalSince(time120) * 3.6 / 1.852)
                                if speed120 > 3.5 { // ASSUMPTION BASED ON MEMORIES
                                    movingDuration += datetime.timeIntervalSince(time120)

                                    let trackpoint = Trackpoint.init(latitude: lat.doubleValue, longitude: lon.doubleValue)
                                    if let s = self?.dateToString(date: datetime) {
                                        trackpoint.title = "\(s) @ \(speed120.roundTo(places: 2)) knots"
                                        trackpoint.speed = speed120.roundTo(places: 2)
                                        trackpoint.subtitle = "\((movingDuration / 60 / 60).roundTo(places: 2)) hours"
                                    }
                                    DispatchQueue.main.async { [weak self]
                                        () -> Void in
                                        viewController.setMovingDuration(duration: (movingDuration / 60 / 60).roundTo(places: 3))
                                        viewController.setFullDuration(duration: (fullDuration / 60 / 60).roundTo(places: 3))
                                        viewController.setMaxSpeed(speed: maxSpeed.roundTo(places: 3))
                                        viewController.setDistance(distance: (fullDistance / 1000 / 1.852).roundTo(places: 3))
                                        viewController.setProcessedPoints(points: i)
                                        viewController.mapView?.addAnnotation(trackpoint)

                                    }
                                }
                                lat120 = lat.doubleValue
                                lon120 = lon.doubleValue
                                time120 = datetime
                            }

                            // calculate distance to previous trackpoint and add to full distance
                            // same to duration :-)
                            if prevLat != 0.0 { // skip the first record as it has no predecessor to do the math with
                                let distance = (self?.haversineDinstance(la1: prevLat, lo1: prevLon, la2: lat.doubleValue, lo2: lon.doubleValue))
                                fullDistance += distance!
                                let diff = (datetime.timeIntervalSince(prevTime))
                                if (diff > 60.0) {
                                    print("Gap of \(diff) seconds at \(prevTime) to \(datetime) Dist: \(distance) >>> \(distance! / diff)")
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
                    () -> Void in

                    let end = Date()
                    viewController.statusField?.stringValue = "Done. Took \((end.timeIntervalSince(strt)).roundTo(places: 2)) seconds."
                    //viewController.mapView?.addAnnotations(annotations)
                    let annos = viewController.mapView?.annotations
                    viewController.mapView?.showAnnotations(annos!, animated: true)
                }
            }
            catch {
                print("\(error)")
            }
        } // end async
    }


    // ---------------------------------------------------------------------------------------------
    // MARK: Date helper
    // ---------------------------------------------------------------------------------------------
    func stringToDate(sDate:String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: sDate)
    }

    // ---------------------------------------------------------------------------------------------
    // MARK: Date helper
    // ---------------------------------------------------------------------------------------------
    func dateToString(date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.string(from: date)
    }



    // ---------------------------------------------------------------------------------------------
    // MARK: Haversine distance math
    // ---------------------------------------------------------------------------------------------
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


    // ---------------------------------------------------------------------------------------------
    // MARK: Exposed loading method
    // ---------------------------------------------------------------------------------------------
    open func foo(path: String) -> () {
        _load(URL(fileURLWithPath: path))
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
