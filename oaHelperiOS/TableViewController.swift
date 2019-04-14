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
    
    var hc = HelperClass()
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "dataCell", for: indexPath) as! TableViewCell
        let paper = self.coreRecords[indexPath.row]
        let title = paper.title ?? ""
        let abstract = paper.description ?? ""
        var yearAbstract = "\(hc.cleanAbstract(txt: abstract))"
        if let year = paper.datePublished {
            yearAbstract = "(\(year.prefix(4))) \(hc.cleanAbstract(txt: abstract))"
        }
        //sets icon incorrectly, needs to be reviewed
        if let urls = paper.downloadUrl{
            if(urls != ""){
                cell.iconImageView.image = UIImage(named: "pdf_icon")
            }
            else{
                cell.iconImageView.image = UIImage(named: "core_icon")
            }
        }
        else{
            cell.iconImageView.image = UIImage(named: "core_icon")
        }
        
        cell.titleLabel.text = title
        cell.detailLabel.text = yearAbstract
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        self.performSegue(withIdentifier: "detailView", sender: indexPath.row)
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
        let detailData = sender as! Int
        if segue.identifier == "detailView" {
            if let nextViewController = segue.destination as? DetailViewController {
                nextViewController.coreRecords = coreRecords
                nextViewController.num = detailData
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
            @unknown default:
                print("fatal error")
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


