//
//  Trackpoint.swift
//  Trip
//
//  Created by Martin Kautz on 28.10.16.
//
//

import Foundation
import MapKit

class Trackpoint: NSObject, MKAnnotation {
    var title: String?
    var subtitle: String?
    var latitude: Double
    var longitude:Double
    var speed: Double?

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public func exposedSpeed() -> (Double) {
        return speed!
    }

}
