//
//  ViewController.swift
//  Wissam_Nasser_digx_werkstuk2
//
//  Created by student on 02/08/2018.
//  Copyright © 2018 student. All rights reserved.
//  Inspiratie uit Les 10 Hoorcolleges
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var myMapView: MKMapView!
    
    let url = URL(string: "https://api.jcdecaux.com/vls/v1/stations?apiKey=6d5071ed0d0b3b68462ad73df43fd9e5479b03d6&contract=Bruxelles-Capitale")
    var locationManager = CLLocationManager()
    
    func getStations(){
        
        let urlRequest = URLRequest(url: self.url!)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
            do{
            DispatchQueue.main.async {
                let task = session.dataTask(with: urlRequest){
                    (data, response, error) in
                    guard error == nil else{
                        print("Error, cannot get JSON")
                        print(error!)
                        return
                    }
                    
                    guard let responseData = data else{
                        print("Error, data was not received")
                        return
                    }
                    
                    let json = try! JSONSerialization.jsonObject(with: responseData, options: []) as! NSArray
                    for station in json {
                        let station = (station as! NSDictionary)
                        let location = ((station ).value(forKey: "position")) as! NSDictionary
                        print(station.value(forKey: "name") as! String + " bikes: "  + String(station.value(forKey: "available_bikes") as! Int64) + " pos: " + String(describing: CLLocationCoordinate2D(latitude: location.value(forKey: "lat") as! CLLocationDegrees, longitude: location.value(forKey: "lng") as! CLLocationDegrees)))
                    }
            }
                
                task.resume()
        }
        }
        
        

        
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        getStations()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let current = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: current, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
    }
    
    
}

