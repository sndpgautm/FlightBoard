//
//  AirportDetail+CoreDataProperties.swift
//  FlightBoard
//
//  Created by iosdev on 07/03/2019.
//  Copyright © 2019 San Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension AirportDetail {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AirportDetail> {
        return NSFetchRequest<AirportDetail>(entityName: "AirportDetail")
    }

    @NSManaged public var airportName: String?
    @NSManaged public var countryCode: String?
    @NSManaged public var countryName: String?
    @NSManaged public var iataCode: String?

}
