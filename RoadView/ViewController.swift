//
//  ViewController.swift
//  RoadView
//
//  Created by Aditya Emani on 3/30/17.
//  Copyright © 2017 Aditya Emani. All rights reserved.
//

import UIKit
import GooglePlaces

enum TravelModes: Int {
    case driving
    case walking
    case bicycling
}


class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    var popupController:CNPPopupController?
    
    @IBOutlet weak var viewMap: GMSMapView!
    @IBOutlet weak var destination: UITextField!
    
    @IBOutlet weak var lblInfo: UILabel!
    
    var locationManager = CLLocationManager()
    
    var didFindMyLocation = false
    
    var mapTasks = MapTasks()
    
    var locationMarker: GMSMarker!
    
    var originMarker: GMSMarker!
    
    var destinationMarker: GMSMarker!
    
    var routePolyline: GMSPolyline!
    
    var markersArray: Array<GMSMarker> = []
    
    var waypointsArray: Array<String> = []
    
    var travelMode = TravelModes.driving
    
    var destinationPlace: GMSPlace!
    var sourcePlace: GMSPlace!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 48.857165, longitude: 2.354613, zoom: 8.0)
        viewMap.camera = camera
        viewMap.delegate = self
        
        viewMap.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeKey.newKey] as! CLLocation
            viewMap.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 10.0)
            viewMap.settings.myLocationButton = true
            
            didFindMyLocation = true
        }

    }
    
    func showPopupWithStyle(_ popupStyle: CNPPopupStyle) {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let title = NSAttributedString(string: destinationPlace.name, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 24), NSParagraphStyleAttributeName: paragraphStyle])
        let lineOne = NSAttributedString(string: destinationPlace.formattedAddress!, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSParagraphStyleAttributeName: paragraphStyle])
        let lineTwo = NSAttributedString(string: String(describing: destinationPlace.website), attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.init(colorLiteralRed: 0.46, green: 0.8, blue: 1.0, alpha: 1.0), NSParagraphStyleAttributeName: paragraphStyle])
        
        let button = CNPPopupButton.init(frame: CGRect(x: 0, y: 0, width: 200, height: 60))
        button.setTitleColor(UIColor.white, for: UIControlState())
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitle("Close Me", for: UIControlState())
        
        button.backgroundColor = UIColor.init(colorLiteralRed: 0.46, green: 0.8, blue: 1.0, alpha: 1.0)
        
        button.layer.cornerRadius = 4;
        button.selectionHandler = { (button) -> Void in
            self.popupController?.dismiss(animated: true)
            print("Block for button: \(String(describing: button.titleLabel?.text))")
        }
        
        let button1 = CNPPopupButton.init(frame: CGRect(x: 220, y: 0, width: 200, height: 60))
        button1.setTitleColor(UIColor.white, for: UIControlState())
        button1.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button1.setTitle("Get Directions", for: UIControlState())
        
        button1.backgroundColor = UIColor.init(colorLiteralRed: 0.46, green: 0.8, blue: 1.0, alpha: 1.0)
        
        button1.layer.cornerRadius = 4;
        button1.selectionHandler = { (button1) -> Void in
            self.popupController?.dismiss(animated: true)
            self.createRoute()
        }
        
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0;
        titleLabel.attributedText = title
        
        let lineOneLabel = UILabel()
        lineOneLabel.numberOfLines = 0;
        lineOneLabel.attributedText = lineOne;
        
        let imageView = UIImageView.init(image: UIImage.init(named: "icon"))
        
        let lineTwoLabel = UILabel()
        lineTwoLabel.numberOfLines = 0;
        lineTwoLabel.attributedText = lineTwo;

        
        let popupController = CNPPopupController(contents:[titleLabel, lineOneLabel, button1, button])
        popupController.theme = CNPPopupTheme.default()
        popupController.theme.popupStyle = popupStyle
        popupController.delegate = self
        self.popupController = popupController
        popupController.present(animated: true)
    }
    
    
    // MARK: IBAction method implementation
    
    @IBAction func changeMapType(_ sender: AnyObject) {
        let actionSheet = UIAlertController(title: "Map Types", message: "Select map type:", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let normalMapTypeAction = UIAlertAction(title: "Normal", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.viewMap.mapType = GMSMapViewType.normal
        }
        
        let terrainMapTypeAction = UIAlertAction(title: "Terrain", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.viewMap.mapType = GMSMapViewType.terrain
        }
        
        let hybridMapTypeAction = UIAlertAction(title: "Hybrid", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.viewMap.mapType = GMSMapViewType.hybrid
        }
        
        let cancelAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
            
        }
        
        actionSheet.addAction(normalMapTypeAction)
        actionSheet.addAction(terrainMapTypeAction)
        actionSheet.addAction(hybridMapTypeAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    
    @IBAction func findAddress(_ sender: AnyObject) {
        let addressAlert = UIAlertController(title: "Address Finder", message: "Type the address you want to find:", preferredStyle: UIAlertControllerStyle.alert)
        
        addressAlert.addTextField { (textField) -> Void in
            textField.placeholder = "Address?"
        }
        
        let findAction = UIAlertAction(title: "Find Address", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            let address = (addressAlert.textFields![0] as UITextField).text!
            
            self.mapTasks.geocodeAddress(address, withCompletionHandler: { (status, success) -> Void in
                if !success {
                    print(status)
                    
                    if status == "ZERO_RESULTS" {
                        self.showAlertWithMessage("The location could not be found.")
                    }
                }
                else {
                    let coordinate = CLLocationCoordinate2D(latitude: self.mapTasks.fetchedAddressLatitude, longitude: self.mapTasks.fetchedAddressLongitude)
                    self.viewMap.camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 14.0)
                    
                    self.setupLocationMarker(coordinate)
                }
            })
            
        }
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
            
        }
        
        addressAlert.addAction(findAction)
        addressAlert.addAction(closeAction)
        
        present(addressAlert, animated: true, completion: nil)
    }
    
    
    func createRoute() {
            if (self.routePolyline) != nil {
                self.clearRoute()
                self.waypointsArray.removeAll(keepingCapacity: false)
            }
            
            let origin = "College station"
            let destination = self.destinationPlace.name
        
            
            self.mapTasks.getDirections(origin, destination: destination, waypoints: nil, travelMode: self.travelMode, completionHandler: { (status, success) -> Void in
                if success {
                    self.configureMapAndMarkersForRoute()
                    self.drawRoute()
                    //self.displayRouteInfo()
                }
                else {
                    print(status)
                }
            })
    }
    
    
    @IBAction func changeTravelMode(_ sender: AnyObject) {
        let actionSheet = UIAlertController(title: "Travel Mode", message: "Select travel mode:", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let drivingModeAction = UIAlertAction(title: "Driving", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.travelMode = TravelModes.driving
            self.recreateRoute()
        }
        
        let walkingModeAction = UIAlertAction(title: "Walking", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.travelMode = TravelModes.walking
            self.recreateRoute()
        }
        
        let bicyclingModeAction = UIAlertAction(title: "Bicycling", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.travelMode = TravelModes.bicycling
            self.recreateRoute()
        }
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
            
        }
        
        actionSheet.addAction(drivingModeAction)
        actionSheet.addAction(walkingModeAction)
        actionSheet.addAction(bicyclingModeAction)
        actionSheet.addAction(closeAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    
    // MARK: CLLocationManagerDelegate method implementation
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            viewMap.isMyLocationEnabled = true
        }
    }
    
    
    // MARK: Custom method implementation
    
    func showAlertWithMessage(_ message: String) {
        let alertController = UIAlertController(title: "GMapsDemo", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
            
        }
        
        alertController.addAction(closeAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    func setupLocationMarker(_ coordinate: CLLocationCoordinate2D) {
        if locationMarker != nil {
            locationMarker.map = nil
        }
        
        locationMarker = GMSMarker(position: coordinate)
        locationMarker.map = viewMap
        
        locationMarker.title = mapTasks.fetchedFormattedAddress
        locationMarker.appearAnimation = GMSMarkerAnimation.pop
        locationMarker.icon = GMSMarker.markerImage(with: UIColor.blue)
        locationMarker.opacity = 0.75
        
        locationMarker.isFlat = true
        locationMarker.snippet = "The best place on earth."
    }
    
    
    func configureMapAndMarkersForRoute() {
        viewMap.camera = GMSCameraPosition.camera(withTarget: mapTasks.originCoordinate, zoom: 9.0)
        
        originMarker = GMSMarker(position: self.mapTasks.originCoordinate)
        originMarker.map = self.viewMap
        originMarker.icon = GMSMarker.markerImage(with: UIColor.green)
        originMarker.title = self.mapTasks.originAddress
        
        destinationMarker = GMSMarker(position: self.mapTasks.destinationCoordinate)
        destinationMarker.map = self.viewMap
        destinationMarker.icon = GMSMarker.markerImage(with: UIColor.red)
        destinationMarker.title = self.mapTasks.destinationAddress
        
        
        if waypointsArray.count > 0 {
            for waypoint in waypointsArray {
                let lat: Double = (waypoint.components(separatedBy: ",")[0] as NSString).doubleValue
                let lng: Double = (waypoint.components(separatedBy: ",")[1] as NSString).doubleValue
                
                let marker = GMSMarker(position: CLLocationCoordinate2DMake(lat, lng))
                //                marker.map = mapView
                marker.icon = GMSMarker.markerImage(with: UIColor.purple)
                
                markersArray.append(marker)
            }
        }
    }
    
    
    func drawRoute() {
        let route = mapTasks.overviewPolyline["points"] as! String
        
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        routePolyline = GMSPolyline(path: path)
        routePolyline.map = viewMap
    }
    
    
    func displayRouteInfo() {
        lblInfo.text = mapTasks.totalDistance + "\n" + mapTasks.totalDuration
    }
    
    
    func clearRoute() {
        originMarker.map = nil
        destinationMarker.map = nil
        routePolyline.map = nil
        
        originMarker = nil
        destinationMarker = nil
        routePolyline = nil
        
        if markersArray.count > 0 {
            for marker in markersArray {
                marker.map = nil
            }
            
            markersArray.removeAll(keepingCapacity: false)
        }
    }
    
    
    func recreateRoute() {
        if (routePolyline) != nil {
            clearRoute()
            
            mapTasks.getDirections(mapTasks.originAddress, destination: mapTasks.destinationAddress, waypoints: waypointsArray, travelMode: travelMode, completionHandler: { (status, success) -> Void in
                
                if success {
                    self.configureMapAndMarkersForRoute()
                    self.drawRoute()
                    self.displayRouteInfo()
                }
                else {
                    print(status)
                }
            })
        }
    }
    
    
    // MARK: GMSMapViewDelegate method implementation
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        if (routePolyline) != nil {
            let positionString = String(format: "%f", coordinate.latitude) + "," + String(format: "%f", coordinate.longitude)
            waypointsArray.append(positionString)
            
            recreateRoute()
        }
    }
    
    @IBAction func autocompleteClicked(_ sender: Any) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        self.showPopupWithStyle(CNPPopupStyle.actionSheet)
        return true
    }
}

extension ViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        destination.text = place.name
        destinationPlace = place
        print("Place: \(place)")
        setupLocationMarker(place.coordinate)
        viewMap.camera = GMSCameraPosition.camera(withTarget: place.coordinate, zoom: 10.0)
        self.showPopupWithStyle(CNPPopupStyle.actionSheet)
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension ViewController : CNPPopupControllerDelegate {
    
    func popupControllerWillDismiss(_ controller: CNPPopupController) {
        print("Popup controller will be dismissed")
    }
    
    func popupControllerDidPresent(_ controller: CNPPopupController) {
        print("Popup controller presented")
    }
}
