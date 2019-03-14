//
//  FlightArriving.swift
//  FlightBoard
//
//  Created by iosdev on 14/03/2019.
//  Copyright © 2019 San Inc. All rights reserved.
//

import Foundation

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
