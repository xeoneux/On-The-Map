//
//  LocationViewController.swift
//  On the Map
//
//  Created by Aayush Kapoor on 16/09/16.
//  Copyright © 2016 Aayush Kapoor. All rights reserved.
//

import MapKit
import UIKit

class LocationViewController: UIViewController, UITextFieldDelegate {

    var mapString: String?
    var coordinate: CLLocationCoordinate2D?

    let submitButton = UIButton(type: .System)
    @IBOutlet weak var searchButton: UIButton!

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textField: UITextField!

    @IBOutlet weak var stackView: UIStackView!

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func viewDidLoad() {
        textView.text = "Where are you\nStudying\nToday?"
        textView.textAlignment = .Center

        textField.delegate = self
        textField.textColor = UIColor.whiteColor()
        textField.backgroundColor = UIColor(red: 2/255, green: 179/255, blue: 228/255, alpha: 1)

        submitButton.addTarget(self, action: #selector(submit), forControlEvents: .TouchUpInside)
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func cancel(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func findOnTheMap(sender: AnyObject) {
        if textField.text?.characters.count != 0 {

            mapString = textField.text
            let searchText = mapString!

            // Remove all views
            stackView.arrangedSubviews.forEach {
                stackView.removeArrangedSubview($0)
            }

            // Add text field view
            textField.text = ""
            textField.keyboardType = .URL
            textField.placeholder = "Enter a Link to Share Here"
            stackView.addArrangedSubview(textField)

            // Add map view
            let mapView = MKMapView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            stackView.addArrangedSubview(mapView)

            // Add button view
            submitButton.setTitle("Submit", forState: .Normal)
            stackView.addArrangedSubview(submitButton)

            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            activityIndicator.center = view.center
            view.addSubview(activityIndicator)
            activityIndicator.startAnimating()

            // Create search request
            let request = MKLocalSearchRequest()
            request.region = mapView.region
            request.naturalLanguageQuery = searchText

            // Start search for location
            let search = MKLocalSearch(request: request)
            search.startWithCompletionHandler {

                activityIndicator.stopAnimating()

                if $0.1 == nil {
                    guard let response = $0.0 else {
                        return
                    }

                    let coordinate = response.mapItems.first?.placemark.coordinate

                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate!
                    mapView.addAnnotation(annotation)

                    let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate!, 5000, 5000)
                    let adjustedRedion = mapView.regionThatFits(viewRegion)
                    mapView.setRegion(adjustedRedion, animated: true)
                    
                    self.coordinate = coordinate
                } else {
                    let alertController = UIAlertController(title: "Location Error", message: "No such location found", preferredStyle: .Alert)
                    let action = UIAlertAction(title: "OK", style: .Default, handler: { _ in
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                    alertController.addAction(action)
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            }
        }
    }

    func submit() {
        if textField.text?.characters.count != 0 {

            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

            let uniqueKey = appDelegate.uniqueKey

            let firstName = appDelegate.firstName
            let lastName = appDelegate.lastName

            let mapString = self.mapString!
            let mediaUrl = textField.text!

            let latitude = Double(self.coordinate!.latitude)
            let longitude = Double(self.coordinate!.longitude)

            let body = "{\"uniqueKey\": \"\(uniqueKey)\", \"firstName\": \"\(firstName)\", \"lastName\": \"\(lastName)\",\"mapString\": \"\(mapString)\", \"mediaURL\": \"\(mediaUrl)\",\"latitude\": \(latitude), \"longitude\": \(longitude)}"

            let api = API(domain: .Parse)
            api.post(body, handler: {
                if $0.error == nil {
                    dispatch_async(dispatch_get_main_queue(), {
                        let alertController = UIAlertController(title: "Post Successful", message: "Successfully posted your location", preferredStyle: .Alert)
                        let action = UIAlertAction(title: "OK", style: .Default, handler: { _ in
                            MapPin.downloadPins()
                            self.dismissViewControllerAnimated(true, completion: nil)
                        })
                        alertController.addAction(action)
                        self.presentViewController(alertController, animated: true, completion: nil)
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        let alertController = UIAlertController(title: "Post Error", message: "Could not post the location", preferredStyle: .Alert)
                        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
                        alertController.addAction(action)
                        self.presentViewController(alertController, animated: true, completion: nil)
                    })
                }
            })
        }
    }
}
