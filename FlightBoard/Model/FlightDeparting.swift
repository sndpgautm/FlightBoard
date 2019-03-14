//
//  FlightDeparting.swift
//  FlightBoard
//
//  Created by iosdev on 14/03/2019.
//  Copyright © 2019 San Inc. All rights reserved.
//

import Foundation

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
