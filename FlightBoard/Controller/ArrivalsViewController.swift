//
//  ArrivalsViewController.swift
//  FlightBoard
//
//  Created by iosdev on 08/03/2019.
//  Copyright © 2019 San Inc. All rights reserved.
//


import Foundation
import UIKit
import SwiftyJSON

class ArrivalsViewController: UIViewController {
    
    //MARK: Properties
    //Holds the iata code used for url
    var airportCodeForURL: String = ""
    //Holds all arrival info
    var flightsArrivingData: [FlightArriving] = []
    @IBOutlet weak var tableView: UITableView!
    
    
    
    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        super.viewDidLoad()
        //Setup Navbar
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.isTranslucent = true
        //navigationController?.navigationBar.tintColor = .red
        
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
        flightsArrivingData.removeAll()
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
                    //Sorting the data in asc order by arrival time
                    self.flightsArrivingData.sort(by: {$0.arrivalTime! < $1.arrivalTime!})
                    DispatchQueue.main.sync {
                        self.tableView.reloadData()
                    }
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

//MARK: UITableViewDelegate and DataSource
extension ArrivalsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(flightsArrivingData.count > 0){
            return flightsArrivingData.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArrivalFlightInfoCell", for: indexPath) as? ArrivalFlightInfoCell else {
            fatalError("The dequeued cell is not an instance of ArrivalFlightInfoCell")
        }
        if(indexPath.row == 0){
            cell.timeLabel.text = "ARR▽"
            cell.cityLabel.text = "FROM"
            cell.flightNoLabel.text = "FLIGHT NO"
            cell.terminalLabel.text = "TERMINAL"
        }else{
            let tempArrData = self.flightsArrivingData[indexPath.row]
            cell.timeLabel.text = tempArrData.arrivalTime
            cell.cityLabel.text = tempArrData.departureCityName
            cell.flightNoLabel.text = tempArrData.flightNo
            if((tempArrData.arrivalTerminal?.isEmpty)!){
                cell.terminalLabel.text = "NA"
            }else{
                cell.terminalLabel.text = tempArrData.arrivalTerminal
            }
        }
        return cell
    }
}
