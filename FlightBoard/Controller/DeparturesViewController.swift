//
//  DeparturesViewController.swift
//  FlightBoard
//
//  Created by iosdev on 08/03/2019.
//  Copyright © 2019 San Inc. All rights reserved.
//

//Struct for DepartureData
struct FlightDeparting:Codable {
    var flightNo: String?
    var arrivalAirportCode: String?
    var departureTerminal: String?
    var departureTime: String?
    var arrivalCityName: String?
    var departureAirportName: String?
    var departureAirportLocalTime: String?
    //Empty Initializer
    init(flightNo: String? = nil, arrivalAirportCode: String? = nil, departureTerminal: String? = nil, departureTime: String? = nil, arrivalCityName: String? = nil, departureAirportName: String? = nil, departureAirportLocalTime: String? = nil){
        self.flightNo = flightNo
        self.arrivalAirportCode = arrivalAirportCode
        self.departureTerminal = departureTerminal
        self.departureTime = departureTime
        self.arrivalCityName = arrivalCityName
        self.departureAirportName = departureAirportName
        self.departureAirportLocalTime = departureAirportLocalTime
    }
}


import Foundation
import UIKit
import SwiftyJSON

class DeparturesViewController: UIViewController {
    
    
    //MARK: Properties
    //Holds the iata code used for url
    var airportCodeForUrl: String = ""
    //Holds all departure info
    var flightsDepartingData: [FlightDeparting] = []
    
    
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
        airportCodeForUrl = airportVC.defaultAirportIata
        getDepartureData()
    }
    
    //MARK: Private Instance Methods
    func getDepartureData(){
        let year = Calendar.current.component(.year, from: Date())
        let month = Calendar.current.component(.month, from: Date())
        let day = Calendar.current.component(.day, from: Date())
        let hourOfDay = Calendar.current.component(.hour, from: Date())
        let dateToBePassed = String(year) + "/" + String(month) + "/"  + String(day) + "/"  + String(hourOfDay)
        
        let urlString = "https://api.flightstats.com/flex/schedules/rest/v1/json/from/\(airportCodeForUrl)/departing/\(dateToBePassed)?appId=47cff971&appKey=864a4ab71222d22dc8d930af4dffe49b"
        guard let url = URL(string: urlString) else {
            fatalError("Failed to create URL")
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            //Handle data
            if let dataRecieved = data{
                do{
                    let jsonData = try JSON(data: dataRecieved)
                    jsonData["scheduledFlights"].array?.forEach({ (flight) in
                        var tempDepartureData = FlightDeparting()
                        tempDepartureData.flightNo = flight["carrierFsCode"].string! + flight["flightNumber"].string!
                        tempDepartureData.arrivalAirportCode = flight["arrivalAirportFsCode"].string!
                        tempDepartureData.departureTerminal = flight["departureTerminal"].string ?? ""
                        tempDepartureData.departureTime = self.convertDateFromServer(flight["departureTime"].string!)
                        let appendix = jsonData["appendix"]
                        appendix["airports"].array?.forEach({ (airport) in
                            if(self.airportCodeForUrl == airport["iata"].string!){
                                tempDepartureData.departureAirportName = airport["name"].string!
                                tempDepartureData.departureAirportLocalTime = self.convertDateFromServer(airport["localTime"].string!)
                            }
                            if(tempDepartureData.arrivalAirportCode == airport["iata"].string!){
                                tempDepartureData.arrivalCityName = airport["city"].string!
                            }
                        })
                        self.flightsDepartingData.append(tempDepartureData)
                    })
                }catch{
                    print("Error serializing json:\(error)")
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
