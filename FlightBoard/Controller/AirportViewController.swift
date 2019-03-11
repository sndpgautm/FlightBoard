//
//  AirportViewController.swift
//  FlightBoard
//
//  Created by iosdev on 06/03/2019.
//  Copyright © 2019 San Inc. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreData

class AirportViewController: UIViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {
    
    
    //MARK: Properties
    //Holds all airport data
    var allAirports = [AirportDetail]()
    //Holds airport data user is searching for
    var filteredAirports = [AirportDetail]()
    //Holds default Airport IATA code
    var defaultAirportIata:String =  "HEL"
    @IBOutlet weak var tableView: UITableView!
    var fetchedResultsController: NSFetchedResultsController<AirportDetail>?
    //Initializing with nil uses the same view in which you're searching to display results
    let searchController = UISearchController(searchResultsController: nil)
    
    
    

    
    
    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.delegate = self
        getAllAirportData()
        super.viewDidLoad()
        //Implement Fetched Results Controller
        let fetchRequest: NSFetchRequest<AirportDetail> = AirportDetail.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "airportName", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: PersistenceService.context, sectionNameKeyPath: "airportName", cacheName: "AirportDetailsCache")
        fetchedResultsController!.delegate = self as NSFetchedResultsControllerDelegate; try? fetchedResultsController?.performFetch()
        //Setup NavBar
        navigationController?.navigationBar.prefersLargeTitles = true
        //navigationItem.rightBarButtonItem = editButtonItem
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = .red
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Airports"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
    }
    
    //Automatically updates UI on change in data in fetchedResultsController
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
    
    //MARK: UISearchResultsUpdatingDelegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }

    
    //MARK: Private Instance Methods
    //Checks if the searchbar is empty
    func searchBarIsEmpty() -> Bool {
        //Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    //Filters the airport info from allAirports Array according to the text provided by user
    func filterContentForSearchText(_ searchText: String) {
        filteredAirports = allAirports.filter({( a : AirportDetail) -> Bool in
            guard let tempName = a.airportName else {
                fatalError("AirportName is empty somehow")
            }
            return (((a.iataCode?.lowercased().contains(searchText.lowercased()))! || tempName.lowercased().contains(searchText.lowercased()))  )
        })
        tableView.reloadData()
    }
    //Checks if user is using searchbar
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    //Gets all the airport info from json file and saves it in an array allAirports for future use
    func getAllAirportData(){
        guard let path = Bundle.main.path(forResource: "AllAirports", ofType: "json") else {return}
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        do{
            let jsonData = try JSON(data: data)
            for (_,subJson) in jsonData[] {
                let tempAirport = AirportDetail(context: PersistenceService.childManagedObjectContext)
                tempAirport.airportName = subJson["nameAirport"].string!
                tempAirport.countryName = subJson["nameCountry"].string!
                tempAirport.countryCode = subJson["codeIso2Country"].string!
                tempAirport.iataCode = subJson["codeIataAirport"].string!
                allAirports.append(tempAirport)
            }
            PersistenceService.saveContext()
            
        }catch{
            print("Error serializing json: \(error)")
        }
        
    }
    

}


//MARK: UITableViewDelegate and DataSource
extension AirportViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering(){
            //Prevents from creating duplicates rows and manages sections accordingly
            return 1
        }
        return fetchedResultsController!.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering(){
            return filteredAirports.count
        }
        if let sections = fetchedResultsController!.sections, sections.count > 0 {
            return sections[section].numberOfObjects
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AirportInfoCell", for: indexPath) as? AirportInfoCell else {
            fatalError("The dequed cell is not an instance of NewsCell")
        }
        let tempAirport: AirportDetail
        if self.isFiltering(){
            tempAirport = self.filteredAirports[indexPath.row]
            cell.accessoryType = .none
        }else {
            tempAirport = (fetchedResultsController?.object(at: indexPath))!
            if(tempAirport.iataCode == defaultAirportIata){
                cell.accessoryType = .checkmark
            }else{
                cell.accessoryType = .none
            }
        }
        //Setup Cell Data
        cell.airportNameLabel.text = tempAirport.airportName
        cell.cityNameLabel.text = tempAirport.countryName
        cell.countryCodeLabel.text = tempAirport.countryCode
        cell.iataLabel.text = tempAirport.iataCode
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isFiltering(){
            defaultAirportIata = filteredAirports[indexPath.row].iataCode!
            self.tableView.cellForRow(at: indexPath)?.accessoryType = .none
            //Only save context if the aiport data is not already saved
            do{
                let tempFetchRequest: NSFetchRequest<AirportDetail> = AirportDetail.fetchRequest()
                tempFetchRequest.predicate = NSPredicate(format: "iataCode ==%@", defaultAirportIata)
                let tempData: [AirportDetail] = try PersistenceService.context.fetch(tempFetchRequest)
                    if(tempData.count == 0){
                        let tempAirportDataToBeSaved = AirportDetail(context: PersistenceService.context)
                        tempAirportDataToBeSaved.airportName = filteredAirports[indexPath.row].airportName
                        tempAirportDataToBeSaved.countryCode = filteredAirports[indexPath.row].countryCode
                        tempAirportDataToBeSaved.countryName = filteredAirports[indexPath.row].countryName
                        tempAirportDataToBeSaved.iataCode = filteredAirports[indexPath.row].iataCode
                        print("coredata doesnot has this item")
                        PersistenceService.saveContext()
                    }else{
                        print("Data is already saved")
                    }
            }catch{
                fatalError("Cannot fetch saved data")
            }
            //Dismiss the search controller
            searchController.isActive = false
            tableView.reloadData()
            
        }else{
            defaultAirportIata = (self.fetchedResultsController?.object(at: indexPath))!.iataCode!
            self.tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            PersistenceService.context.delete((fetchedResultsController?.object(at: indexPath))!)
            PersistenceService.saveContext()
            //Reloading data instead of deletRows() as it doesnot work and keeps giving index path error
            //self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.tableView.reloadData()
        }
    }
    
}

