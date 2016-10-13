//
//  WindowController.swift
//  Trip
//
//  Created by Martin Kautz on 13.10.16.
//
//

import Cocoa


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


        DispatchQueue.global().async {

            guard let
                data = try? Data(contentsOf: url)
                else { return }

            do {
                let xmlDoc = try AEXMLDocument(xml: data)
                var prevLat:Double = 0.0
                var prevLon:Double = 0.0
                var completeDistance:Double = 0.0
                var i = 0
                for item in xmlDoc.root["trk"].children {
                    if item.name == "trkseg" {
                        for pos in item.children {
                            if let lat = pos.attributes["lat"]  {
                                if let lon = pos.attributes["lon"]  {
                                    if prevLat != 0.0 {
                                        completeDistance += (self.haversineDinstance(la1: prevLat, lo1: prevLon, la2: lat.doubleValue, lo2: lon.doubleValue))
                                    }
                                    prevLat = lat.doubleValue
                                    prevLon = lon.doubleValue
                                }
                            }
                            i = i + 1;
                        }
                    }
                }

                DispatchQueue.main.async {
                    print("Number of pos: \(i)")
                    print("Distance     : \(completeDistance / 1000) km")
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "DidGetData"), object: nil, userInfo: nil);
                }
            }
            catch {
                print("\(error)")
            }

        }
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
