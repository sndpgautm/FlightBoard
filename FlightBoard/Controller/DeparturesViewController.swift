//
//  DeparturesViewController.swift
//  FlightBoard
//
//  Created by iosdev on 08/03/2019.
//  Copyright © 2019 San Inc. All rights reserved.
//


import Foundation
import UIKit
import SwiftyJSON

class DeparturesViewController: UIViewController {
    
    
    //MARK: Properties
    //Holds the iata code used for url
    var airportCodeForUrl: String = ""
    //Holds all departure info
    var flightsDepartingData: [FlightDeparting] = []
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
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
        airportCodeForUrl = airportVC.defaultAirportIata
        getDepartureData()
    }
    
    //MARK: Private Instance Methods
    func getDepartureData(){
        flightsDepartingData.removeAll()
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
                    //sorting the data in asc order by departure time
                    self.flightsDepartingData.sort(by: {$0.departureTime! < $1.departureTime!})
                    DispatchQueue.main.sync {
                        self.tableView.reloadData()
                    }
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

//MARK: UITableViewDelegate and DataSource
extension DeparturesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(flightsDepartingData.count > 0){
            return flightsDepartingData.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DepartureFlightInfoCell", for: indexPath) as? DepartureFlightInfoCell else {
            fatalError("The dequeued cell is not an instance of DepartureFlightInfoCell")
        }
        if(indexPath.row == 0){
            cell.dTimeLabel.text = "DEP△"
            cell.dCityLabel.text = "TO"
            cell.dFlightNoLabel.text = "FLIGHT NO"
            cell.dTerminalLabel.text = "TERMINAL"
        }else{
            let tempDepData = self.flightsDepartingData[indexPath.row]
            cell.dTimeLabel.text = tempDepData.departureTime
            cell.dCityLabel.text = tempDepData.arrivalCityName
            cell.dFlightNoLabel.text = tempDepData.flightNo
            if((tempDepData.departureTerminal?.isEmpty)!){
                cell.dTerminalLabel.text = "NA"
            }else{
                cell.dTerminalLabel.text = tempDepData.departureTerminal
            }
        }
        return cell
    }
}
