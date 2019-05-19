//
//  StatisticsViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 26.04.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit

class StatisticsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet var myView: UIView!
    
    let settings = SettingsBundleHelper()
    var statisticsObject : [StatsValues] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var explainerLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createStatisticsObject()
        tableView.delegate = self
        tableView.dataSource = self
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.checkAction))
        self.myView.addGestureRecognizer(gesture)
    }
    
    @objc func checkAction(sender : UITapGestureRecognizer) {
        // Do what you want
        setExplainerLabelDefault()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setExplainerLabelDefault()
        createStatisticsObject()
        tableView.reloadData()
    }
    
    func setExplainerLabelDefault(){
        explainerLabel.text = NSLocalizedString("Please select an entry above for an explanation of the value.", comment: "")
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statisticsObject.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "statCell", for: indexPath)
        cell.textLabel?.text = statisticsObject[indexPath.row].textLabel
        cell.detailTextLabel?.text = statisticsObject[indexPath.row].detailTextLabel
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        explainerLabel.text = statisticsObject[indexPath.row].explainerLabel
    }
    
    func createStatisticsObject(){
        var tmpStatisticsObject : [StatsValues] = []
        
        let oa_search = StatsValues()
        oa_search.textLabel = NSLocalizedString("Open Access Searches", comment: "")
        oa_search.detailTextLabel = "\(settings.getOACount(key: "oa_search"))"
        oa_search.explainerLabel = NSLocalizedString("The number of Open Access searches conducted within, or by sending text to, the app. Search API is kindly provided by core.ac.uk!", comment: "")
        tmpStatisticsObject.append(oa_search)
  
        let core_pdf = StatsValues()
        core_pdf.textLabel = NSLocalizedString("Number of core.ac.uk PDFs", comment: "")
        core_pdf.detailTextLabel = "\(settings.getOACount(key: "core_pdf"))"
        core_pdf.explainerLabel = NSLocalizedString("Number of PDF documents accessed from core.ac.uk through this app. This would be a direct result of an Open Access Search.", comment: "")
        tmpStatisticsObject.append(core_pdf)
        
        let oa_found = StatsValues()
        oa_found.textLabel = NSLocalizedString("Unpaywall.org Found", comment: "")
        oa_found.detailTextLabel = "\(settings.getOACount(key: "oa_found"))"
        oa_found.explainerLabel = NSLocalizedString("Number of paywalls avoided, thanks to unpaywall.org. This value gets incremented, when you use the Safari Action Extension and an Open Access Alternative is found, whether you clicked it, or not.", comment: "")
        tmpStatisticsObject.append(oa_found)
        
        let bookmark_count = StatsValues()
        bookmark_count.textLabel = NSLocalizedString("Number of Bookmarks", comment: "")
        bookmark_count.detailTextLabel = "\(settings.getOACount(key: "bookmark_count"))"
        bookmark_count.explainerLabel = NSLocalizedString("Number of bookmarks currently in your bookmarks database.", comment: "")
        tmpStatisticsObject.append(bookmark_count)
        
        let sync_date = StatsValues()
        sync_date.textLabel = NSLocalizedString("Last iCloud Sync Date", comment: "")
        let syncDate = settings.getSyncDate(type: "sync_date")
        if(syncDate != "0"){
            sync_date.detailTextLabel = "\(syncDate)"
        }
        else{
            sync_date.detailTextLabel = NSLocalizedString("Never", comment: "")
        }
        sync_date.explainerLabel = NSLocalizedString("The date, we have last synced your bookmarks with iCloud. Please note that we will only sync once every two hours, unless you manually initiate a sync. See Settings to change your iCloud Sync preference.", comment: "")
        tmpStatisticsObject.append(sync_date)
        
        let share_date = StatsValues()
        share_date.textLabel = NSLocalizedString("Last Statstics Share Date", comment: "")
        let shareDate = settings.getShareDate()
        if(shareDate != "0"){
            share_date.detailTextLabel = "\(shareDate)"
        }
        else{
            share_date.detailTextLabel = NSLocalizedString("Never", comment: "")
        }
        share_date.explainerLabel = NSLocalizedString("The date, these statistics have last been shared with the app developer. See Settings to change your sharing preference.", comment: "")
        tmpStatisticsObject.append(share_date)
        
        statisticsObject = tmpStatisticsObject
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    
}

class StatsValues {
    var textLabel : String = ""
    var detailTextLabel : String = ""
    var explainerLabel : String = ""
}