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
    
    func checkCore(search: String){
        //print("We are starting a search")
        
        self.loadingData = true
        let apiKey = self.hc.getAPIKeyFromPlist(key: "core")
        // if the apiKey is empty show an error, but we can't recover from it
        if(apiKey == ""){
            //need some sort of error
            return
        }
        
        let nextPage = self.page + 1
        self.page = nextPage
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        // lets get the data via the search
        self.hc.checkCore(search: search, apiKey: apiKey, page: nextPage) { (res) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            self.loadingData = false
            switch res {
            case .success(let data):
                    print(data)
            //print("we are done with a search")
//                DispatchQueue.main.async {
//
//                    let myItems = self.handleCoreData(data: data)
//                    if (myItems.count > 0){
//                        for item in myItems{
//                           self.coreRecords.append(item)
//                        }
//                        self.tableView.tableFooterView?.removeFromSuperview()
//                        self.tableView.reloadData()
//                    }
//
//
//                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func handleCoreData(data: Data) -> [Items]{
        
        do{
            let coreData = try JSONDecoder().decode(Core.self, from: data)
            if(coreData.status == "OK"){
                if let totalHits = coreData.totalHits{
                    let tmpMaxPage = Double(Double(totalHits) / 50)
                    self.maxPage = tmpMaxPage.rounded(.up)
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
                notification.notificationOccurred(.warning)
                showErrorAlert(title: title, message: message)
                return []
            }
            
        }
        catch let jsonError{
            let title = NSLocalizedString("❗This wasn't meant to happen", comment: "unforseen error at data decoding")
            let message = NSLocalizedString("We encountered an error, which we thought you'd never see. Sorry about that. Please try again!", comment: "body for alert, when there was an error")
            notification.notificationOccurred(.error)
            showErrorAlert(title: title, message: message)
            print(jsonError)
            return []
        }
    }
    
    func handleEPMCData(data: Data) -> [EpmcItems]{
        do{
            let epmcData = try JSONDecoder().decode(EPMC.self, from: data)
            if let totalHits = epmcData.hitCount {
                if (totalHits > 0) {
                    let tmpMaxPage = Double(Double(totalHits) / 50)
                    self.maxPage = tmpMaxPage.rounded(.up)
                    let formatedNumber = formatThousandSeperators(number: "\(totalHits)")
                    let hitCountText = String(format: NSLocalizedString("%@ Hits", comment: "Hit count indicator"), formatedNumber)
                    self.hits = hitCountText
                    self.title = hitCountText
                    if let epmcRecords = epmcData.resultList?.result{
                        return epmcRecords
                    }
                    else{
                        return []
                    }
                }
                else{
                    let title = NSLocalizedString("😢 No Results", comment: "No results message")
                    let message = NSLocalizedString("Sadly there were no results for your search. Please check your search terms or rephrase your query and try again.", comment: "message for no hits")
                    notification.notificationOccurred(.warning)
                    showErrorAlert(title: title, message: message)
                    return []
                }
            }
            else{
                let title = NSLocalizedString("😢 No Results", comment: "No results message")
                let message = NSLocalizedString("Sadly there were no results for your search. Please check your search terms or rephrase your query and try again.", comment: "message for no hits")
                notification.notificationOccurred(.warning)
                showErrorAlert(title: title, message: message)
                return []
            }
        }
        catch let jsonError{
            let title = NSLocalizedString("❗This wasn't meant to happen", comment: "unforseen error at data decoding")
            let message = NSLocalizedString("We encountered an error, which we thought you'd never see. Sorry about that. Please try again!", comment: "body for alert, when there was an error")
            notification.notificationOccurred(.error)
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


