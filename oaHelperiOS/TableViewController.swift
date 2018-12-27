//
//  TableViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 13.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import UIKit
import SafariServices

class TableViewController: UITableViewController {
    
    var searchTerm = ""
    var apiData = Data()
    var papers = [Papers]()
    var coreRecords = [Items]()
    var hits = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.coreRecords = handleCoreData(data: self.apiData)
        
        self.title = self.hits
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = self.hits
    }

    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.coreRecords.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dataCell", for: indexPath)
        let paper = self.coreRecords[indexPath.row]
        let title = paper.title ?? ""
        let abstract = paper.description ?? ""
        var yearAbstract = "\(abstract)"
        if let year = paper.datePublished {
            yearAbstract = "(\(year.prefix(4))) \(abstract)"
        }
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = yearAbstract
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let detailData = DetailData()
        detailData.title = self.coreRecords[indexPath.row].title ?? ""
        detailData.author = self.coreRecords[indexPath.row].authors ?? []
        detailData.abstract = self.coreRecords[indexPath.row].description ?? ""
        
        if let urls = self.coreRecords[indexPath.row].downloadUrl{
            if(urls != ""){
                detailData.url = urls
                detailData.buttonLabel = NSLocalizedString("Access Full Text", comment: "button, access full text")
            }
            else{
                if let id = self.coreRecords[indexPath.row].id{
                    detailData.url = "https://core.ac.uk/display/\(id)"
                    detailData.buttonLabel = NSLocalizedString("View Record at core.ac.uk", comment: "button, core.ac.uk document")
                }
                else{
                    detailData.url = ""
                }
                
            }
        }
        
        self.performSegue(withIdentifier: "detailView", sender: detailData)
    }
    
    
    func handleData(data: Data) -> [Papers]{
        
        do{
            let dessimData = try JSONDecoder().decode(Dessim.self, from: data)
            let papers = dessimData.papers
            return papers
            
        }
        catch let jsonError{
            print("\(jsonError)")
            return []
        }
    }
    
    func handleCoreData(data: Data) -> [Items]{
        
        do{
            let coreData = try JSONDecoder().decode(Core.self, from: data)
            if(coreData.status == "OK"){
                if let totalHits = coreData.totalHits{
                    let formatedNumber = formatThousandSeperators(number: "\(totalHits)")
                    let hitCountText = String(format: NSLocalizedString("%@ Hits", comment: "Hit count indicator"), formatedNumber)
                    self.hits = hitCountText
                    self.title = hitCountText
                    if let coreRecords = coreData.data{
                        return coreRecords
                    }
                    else{
                        return []
                    }
                }
                else{
                    return []
                }
                
            }
            else{
                let title = NSLocalizedString("😢 No Results", comment: "No results message")
                let message = NSLocalizedString("Sadly there were no results for your search. Please check your search terms or rephrase your query and try again.", comment: "message for no hits")
                showErrorAlert(title: title, message: message)
                return []
            }
            
        }
        catch let jsonError{
            let title = NSLocalizedString("❗This wasn't meant to happen", comment: "unforseen error at data decoding")
            let message = NSLocalizedString("We encountered an error, which we thought you'd never see. Sorry about that. Please try again!", comment: "body for alert, when there was an error")
            showErrorAlert(title: title, message: message)
            print(jsonError)
            return []
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.title = NSLocalizedString("Search Results", comment: "Search Results String used as back-button")
        let detailData = sender as! DetailData
        if segue.identifier == "detailView" {
            if let nextViewController = segue.destination as? DetailViewController {
                nextViewController.coreRecord = detailData
            }
        }
    }
    

    func showErrorAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                self.navigationController?.popViewController(animated: true)
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
                
                
            }}))
        self.present(alert, animated: true, completion: nil)
    }
 
    func formatThousandSeperators(number: String) -> String{
        if let num = Int(number){
            let myNumber = NSNumber(value: num)
            let fmt = NumberFormatter()
            fmt.numberStyle = .decimal
            if let myReturn = fmt.string(from: myNumber){
                return myReturn
            }
            else{
                return number
            }
        }
        else{
            return number
        }
        
    }
    
}


