//
//  ViewController.swift
//  testLocation
//
//  Created by Delicious on 9/10/17.
//  Copyright © 2017 Delicious. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import GeoFire
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var InfoLabel: UILabel!
    @IBAction func onButtonTrackClick(_ sender: Any) {
        mainMapView.removeOverlays(mainMapView.overlays)
        getData();
    }
    
    @IBAction func onButtonClearClick(_ sender: Any) {
        mainMapView.removeOverlays(mainMapView.overlays)
    }
    
    var manager:CLLocationManager!
    var myLocations: [CLLocation] = []
    var tempLocations: [CLLocation] = []
    var lastLocation:CLLocation=CLLocation()
    var polyline:MKPolyline!
    var geoFire: GeoFire!
    var geoFireRef: DatabaseReference!
    var count=1
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //Setup our Location Manager
        manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest  //default 5m
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        
        
        //Setup our Map View
        mainMapView.delegate = self
        mainMapView.mapType=MKMapType.standard
        mainMapView.showsUserLocation = true
       
        geoFireRef = Database.database().reference().child("userLocation")
        geoFire = GeoFire(firebaseRef: geoFireRef)
        //getData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currLocation=locations[0]
        //tempLocations.append(locations[0])
        
        let distanceInMeters = currLocation.distance(from: lastLocation) // result is in meters
        if(distanceInMeters>2){
            InfoLabel.text = "\(count)  :  \(currLocation)"
            count=count+1
            lastLocation=currLocation
            addLocation(userLocation: currLocation)
            myLocations.append(currLocation)
            
            if (myLocations.count > 1){
                let sourceIndex = myLocations.count - 1
                let destinationIndex = myLocations.count - 2
                
                let c1 = myLocations[sourceIndex].coordinate
                let c2 = myLocations[destinationIndex].coordinate
                let a = [c1, c2]
                let polyline = MKPolyline(coordinates: a, count: a.count)
                mainMapView.add(polyline)
            }
            let spanX = 0.007
            let spanY = 0.007
            let newRegion = MKCoordinateRegion(center: currLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
            mainMapView.setRegion(newRegion, animated: true)
        }
        
    }
    
    func addLocation(userLocation:CLLocation) {
        print("addLocation")
        geoFireRef.child(userLocation.timestamp.description).setValue(["long":userLocation.coordinate.longitude,"lat":userLocation.coordinate.latitude])

    }
    func getData() {
        
        _ = geoFireRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let fireDatas = snapshot.value as? [String : [String:Double]] ?? [:]
            self.myLocations.removeAll()
            for (_, val) in fireDatas {
                self.myLocations.append(CLLocation(latitude: val["lat"]!, longitude: val["long"]!))
            }
            self.addPolylineToMap(locations: self.myLocations)
            self.lastLocation=self.myLocations[self.myLocations.count-1]
            
        })
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        var polylineRenderer = MKPolylineRenderer()
        if overlay is MKPolyline {
            polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.red
            polylineRenderer.lineWidth = 2
            return polylineRenderer
        }
        
        return polylineRenderer
    }
    
   
    func addPolylineToMap(locations: [CLLocation]) {
        if(locations.count>2){
            let coordinates = locations.map { $0.coordinate }
            print("\n coordinates=>", coordinates)
            let newPolyline=MKPolyline(coordinates: coordinates, count: coordinates.count)
//            self.mainMapView.exchangeOverlay(newPolyline, with: self.polyline)
//            self.polyline=newPolyline
//            
            self.mainMapView.add(newPolyline)
        }
    }
}

