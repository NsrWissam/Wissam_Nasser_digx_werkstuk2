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
import CoreData
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBAction func refreshStations(_ sender: Any) {
        refresh()
    }
    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet weak var updateTimeLabel: UILabel!
    
    var villoStations = Array<Station>()
    let url = URL(string: "https://api.jcdecaux.com/vls/v1/stations?apiKey=6d5071ed0d0b3b68462ad73df43fd9e5479b03d6&contract=Bruxelles-Capitale")
    var locationManager = CLLocationManager()
    
    func getStations(){
        
        let urlRequest = URLRequest(url: self.url!)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
            else{
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let stationFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Station")
        stationFetch.returnsObjectsAsFaults=false
        
        // Check coreData for stations
        //if stations.count > 0
        // append stations to an array
        // else API call for stations data
        do
        {
            let coreVilloStations = try! managedContext.fetch(stationFetch) as! [Station]
            if coreVilloStations.count > 0 {
                    for station in coreVilloStations{
                        self.villoStations.append(station)
                    }
            } else
            {
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
                            let stationDict = (station as! NSDictionary)
                            let position = ((stationDict).value(forKey: "position")) as! NSDictionary
                            let package = NSEntityDescription.insertNewObject(forEntityName: "Station", into: managedContext) as! Station
                            
                            package.number = (stationDict.value(forKey: "number") as? Int64)!
                            package.name = (stationDict.value(forKey: "name") as! String)
                            package.longitude = (position.value(forKey: "lng") as! Double)
                            package.latitude = (position.value(forKey: "lat") as! Double)
                            package.availableBikes = (stationDict.value(forKey: "available_bikes") as? Int64)!
                            package.availableBikeStands = (stationDict.value(forKey: "available_bike_stands") as? Int64)!
                            package.bikeStands = (stationDict.value(forKey: "bike_stands") as? Int64)!
                            package.banking = (stationDict.value(forKey: "banking") as! Bool)
                            package.address = (stationDict.value(forKey: "address") as! String)
                            package.bonus = (stationDict.value(forKey: "bonus") as! Bool)
                            package.status = (stationDict.value(forKey: "status") as! String)
                            package.contractName = (stationDict.value(forKey: "contract_name") as! String)
                            package.updateTime = (stationDict.value(forKey: "last_update") as? Int64)!
                            
                            self.villoStations.append(package)
                        }
                        do{
                            try managedContext.save()
                            self.showStationsOnMap()
                        } catch {
                            fatalError("Failure to save the context: \(error)")
                        }
                    }
                    task.resume()
                    }
                }
        }
    }
    
    func showStationsOnMap(){
        for station in villoStations{
            DispatchQueue.main.async{
                
                var fietsenString = "\n bikes available: " + String(station.bikeStands - station.availableBikes)
                var standString = "\n stands free: " + String(station.availableBikeStands)
                var statusString:String?
            
                
                if(station.status == "OPEN"){
                    statusString = "open"
                } else{
                    statusString = "closed"
                    fietsenString = "\n no bikes available"
                }
                
                let subtitle = statusString! + fietsenString + standString
                
                //annotation loop
               
                let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(station.latitude, station.longitude)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = location
                    annotation.title = station.name
                    annotation.subtitle = String(subtitle)
            
                self.myMapView.addAnnotation(annotation)
            }
        }
    }
    
    
    func refresh(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
            else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Station")
        request.returnsObjectsAsFaults = false
        do {
            let results = try managedContext.fetch(request)
            for managedObject in results {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                managedContext.delete(managedObjectData)
            }
        } catch let error as NSError {
            print("\(error) \(error.userInfo)")
        }
        villoStations = []
        self.myMapView.removeAnnotations(self.myMapView.annotations)
        getStations()
        let timestamp = DateFormatter()
        timestamp.dateStyle = .short
        timestamp.timeStyle = .medium
        timestamp.locale = Locale(identifier: "en_GB")
        updateTimeLabel.text = timestamp.string(from: NSDate() as Date)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        refresh()
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

