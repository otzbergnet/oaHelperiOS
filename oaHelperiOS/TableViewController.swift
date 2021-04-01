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
    var searchResults = SearchResult()
    var papers = [Papers]()
    var coreRecords = [Items]()
    var epmcRecords = [EpmcItems]()
    var hits = ""
    var page = 1
    var maxPage = 1.00
    var search = ""
    
    var hc = HelperClass()
    var settings = SettingsBundleHelper()
    var isEPMC = false
    let notification = UINotificationFeedbackGenerator()
    
    var loadingData = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "\(self.searchResults.hitCount)"
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = "\(self.searchResults.hitCount)"
    }

    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.searchResults.records.count
        
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dataCell", for: indexPath) as! TableViewCell
        let paper = self.searchResults.records[indexPath.row]
        let title = paper.title
        let abstract = paper.abstract
        let yearAbstract = "(\(paper.year)) \(hc.cleanAbstract(txt: abstract))"
        if(paper.hasFT){
            cell.iconImageView.image = UIImage(named: "pdf_icon")
        }
        else{
            cell.iconImageView.image = UIImage(named: "core_icon")
        }
        
        cell.titleLabel.text = title
        cell.detailLabel.text = yearAbstract
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = self.coreRecords.count - 1
        if !loadingData && indexPath.row == (lastElement - 25) && self.page < Int(self.maxPage){
            let spinner = UIActivityIndicatorView(style: .gray)
            spinner.startAnimating()
            spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: tableView.bounds.width, height: CGFloat(44))
            self.tableView.tableFooterView = spinner
            self.tableView.tableFooterView?.backgroundColor = UIColor(red: 0.984, green: 0.627, blue: 0.216, alpha: 1.00)
            self.tableView.tableFooterView?.isHidden = false
            //self.checkCore(search: self.search)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.performSegue(withIdentifier: "detailView", sender: indexPath.row)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.title = NSLocalizedString("Search Results", comment: "Search Results String used as back-button")
        let detailData = sender as! Int
        if segue.identifier == "detailView" {
            if let nextViewController = segue.destination as? DetailViewController {
                nextViewController.searchResults = self.searchResults
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


