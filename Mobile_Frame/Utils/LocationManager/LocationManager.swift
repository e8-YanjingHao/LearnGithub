//
//  LocationManager.swift
//  MobileFrame
//
//  Created by ERIC on 2022/1/10.
//


import Foundation
import CoreLocation

internal typealias LocationComplateBlock = (_ lat: CGFloat, _ lng: CGFloat) -> Void

internal class LocationManager: CLLocationManager, CLLocationManagerDelegate {
    
    static var shared = LocationManager()
    
    var locationComplateBlock: LocationComplateBlock?
    
    override init() {
        super.init()
        
        self.delegate = self
    }
    
    func startRequestLocation() {
        if (CLLocationManager.authorizationStatus() == .denied) {
            self.requestWhenInUseAuthorization()
        } else {
            self.startUpdatingLocation()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if status == .notDetermined {
                self.startRequestLocation()
            } else if (status == .restricted || status == .denied) {
                
            }
        }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last!.coordinate
        let latitude = coordinate.latitude;
        let longitude = coordinate.longitude;
        
        self.locationComplateBlock?(latitude, longitude)
    }
}
