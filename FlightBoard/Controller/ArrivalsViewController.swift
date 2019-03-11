//
//  ArrivalsViewController.swift
//  FlightBoard
//
//  Created by iosdev on 08/03/2019.
//  Copyright © 2019 San Inc. All rights reserved.
//

//Struct for Arrival Data
struct FlightArriving:Codable {
    var flightNo: String?
    var departureAirportCode: String?
    var arrivalTerminal: String?
    var arrivalTime: String?
    var departureCityName: String?
    var arrivalAirportName: String?
    var arrivalAirportLocalTime: String?
    //Empty Initializer
    init(flightNo: String? = nil, departureAirportCode: String? = nil, arrivalTerminal: String? = nil, arrivalTime: String? = nil, departureCityName: String? = nil, arrivalAirportName: String? = nil, arrivalAirportLocalTime: String? = nil){
        self.flightNo = flightNo
        self.departureAirportCode = departureAirportCode
        self.arrivalTerminal = arrivalTerminal
        self.arrivalTime = arrivalTime
        self.departureCityName = departureCityName
        self.arrivalAirportName = arrivalAirportName
        self.arrivalAirportLocalTime = arrivalAirportLocalTime
    }
}



import Foundation
import UIKit
import SwiftyJSON

class ArrivalsViewController: UIViewController {
    
    //MARK: Properties
    //Holds the iata code used for url
    var airportCodeForURL: String = ""
    //Holds all arrival info
    var flightsArrivingData: [FlightArriving] = []
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Setup Navbar
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = .red
        
    }
    
    //Gets iataCode form airportViewController
    override func viewWillAppear(_ animated: Bool) {
        let navController = self.tabBarController?.viewControllers![0] as! UINavigationController
        let airportVC = navController.topViewController as! AirportViewController
        airportCodeForURL = airportVC.defaultAirportIata
        getArrivalData()
    }
    
    //MARK: Private Instance methods
    func getArrivalData() {
        let year = Calendar.current.component(.year, from: Date())
        let month = Calendar.current.component(.month, from: Date())
        let day = Calendar.current.component(.day, from: Date())
        let hourOfDay = Calendar.current.component(.hour, from: Date())
        let dateToBePassed = String(year) + "/" + String(month) + "/"  + String(day) + "/"  + String(hourOfDay)
        
        let urlString = "https://api.flightstats.com/flex/schedules/rest/v1/json/to/\(airportCodeForURL)/arriving/\(dateToBePassed)?appId=47cff971&appKey=864a4ab71222d22dc8d930af4dffe49b"
        guard let url = URL(string: urlString) else {
            fatalError("Failed to create URL")
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            //Handle data
            if let dataRecieved = data {
                do{
                    let jsonData = try JSON(data: dataRecieved)
                    jsonData["scheduledFlights"].array?.forEach({ (flight) in
                        //JSONParsing using SwiftyJson
                        var tempArrivalData = FlightArriving()
                        tempArrivalData.flightNo = flight["carrierFsCode"].string! + flight["flightNumber"].string!
                        tempArrivalData.departureAirportCode = flight["departureAirportFsCode"].string!
                        tempArrivalData.arrivalTerminal = flight["arrivalTerminal"].string ?? ""
                        tempArrivalData.arrivalTime = self.convertDateFromServer(flight["arrivalTime"].string!)
                        let appendinx = jsonData["appendix"]
                        appendinx["airports"].array?.forEach({ (airport) in
                            if (self.airportCodeForURL == airport["iata"].string!){
                                tempArrivalData.arrivalAirportName = airport["name"].string!
                                tempArrivalData.arrivalAirportLocalTime = self.convertDateFromServer(airport["localTime"].string!)
                            }
                            if(tempArrivalData.departureAirportCode == airport["iata"].string!){
                                tempArrivalData.departureCityName =  airport["city"].string!
                            }
                        })
                        self.flightsArrivingData.append(tempArrivalData)
                    })
                }catch{
                    print("Error serializing json: \(error)")
                }
            }
        }
        task.resume()
    }
    
    //Converts date from server to HH:mm format
    func convertDateFromServer(_ givenString: String) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        let dateFromString = dateFormatter.date(from: givenString)
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: dateFromString!)
    }
    
    
    
    
    
}
