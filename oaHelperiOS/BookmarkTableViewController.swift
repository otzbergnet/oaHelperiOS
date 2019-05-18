//
//  BookmarkTableViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 24.02.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit
import Foundation
import SafariServices
import Network

class BookmarkTableViewController: UITableViewController {
    
    var bookMarkList : [BookMarkObj] = []
    var bookMarkData = BookMarkData()
    let settings = SettingsBundleHelper()
    let helper = HelperClass()
    
    var activeBookMarkCheck = false
    let messageFrame = UIView()
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    var isOnline = true
    
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    @IBOutlet weak var cloudSyncButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.title = "Bookmarks"

        let refreshControl = UIRefreshControl()
        let title = "Syncing Changes with iCloud"
        refreshControl.attributedTitle = NSAttributedString(string: title)
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        //self.initiateSync()
        self.bookMarkList = self.bookMarkData.getAllBookMarks()
        self.settings.setBookMarkCount(bookMarkCount : self.bookMarkList.count)
        
        
        self.showCloudSyncButton()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if(self.settings.getSettingsValue(key: "bookmarks") == false){
            performSegue(withIdentifier: "noBookMarkPopover", sender: self)
        }
        self.networkAvailable()
        self.bookMarkList = self.bookMarkData.getAllBookMarks()
        self.settings.setBookMarkCount(bookMarkCount : self.bookMarkList.count)
        self.tableView.reloadData()
        self.initiateSync()
        self.showCloudSyncButton()
    }
    
    @objc func refreshData(refreshControl: UIRefreshControl) {
        if(self.settings.getSettingsValue(key: "bookmarks_icloud")){
          cloudSync(isRefresh: true)
        }
        else{
            self.bookMarkList = self.bookMarkData.getAllBookMarks()
            self.settings.setBookMarkCount(bookMarkCount : self.bookMarkList.count)
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.bookMarkList.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bookMarkCell", for: indexPath)

        if (!self.bookMarkList[indexPath.row].synced){
            //print("this record: \(String(describing: self.bookMarkList[indexPath.row].title)) needs to be synced")
        }
        if(self.bookMarkList[indexPath.row].title != ""){
            cell.textLabel?.text = self.bookMarkList[indexPath.row].title
        }
        else{
            cell.textLabel?.text = "-"
        }
        
        if(self.bookMarkList[indexPath.row].pdf != ""){
            cell.detailTextLabel?.text = "\(String(describing: self.bookMarkList[indexPath.row].pdf!))"
        }
        else{
            cell.detailTextLabel?.text = "\(String(describing: self.bookMarkList[indexPath.row].url!))"
        }
        
        return cell
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            
            if let url = self.bookMarkList[indexPath.row].url {
                self.bookMarkData.deleteBookmark(url: url)
                self.bookMarkList.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let myurl = self.bookMarkList[indexPath.row].pdf {
            if(myurl != ""){
                goToDocument(myurl: myurl)
                return
            }
        }
        if let myurl = self.bookMarkList[indexPath.row].url {
            if(myurl != ""){
                goToDocument(myurl: myurl)
                return
            }
        }
        return
        
    }
    
    func goToDocument(myurl: String){
        if(myurl != ""){
            let url = URL(string: myurl.trimmingCharacters(in: .whitespacesAndNewlines))
            let vc = SFSafariViewController(url: url!)
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func initiateSync(){
        let date = settings.getSyncDate(type: "sync_date")
        if(!helper.recentSynced(lastDate: date)){
            cloudSync(isRefresh: false)
        }
    }
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    func bookMarkCheck(isRefresh: Bool, completion : @escaping (_ type : String) -> ()){
        if self.activeBookMarkCheck{
            completion("active")
        }
        else{
            self.activeBookMarkCheck = true
            if(self.settings.getSettingsValue(key: "bookmarks_icloud")){
                if(!self.isOnline){
                    DispatchQueue.main.async {
                        if(!isRefresh){
                           self.effectView.removeFromSuperview()
                        }
                    }
                    completion("done")
                }
                if(!isRefresh){
                    showCloudSyncMessage()
                }
                
                self.bookMarkData.syncCloudChanges(){ (type : String) in
                    if(type == "done"){
                        DispatchQueue.main.async {
                            if(!isRefresh){
                               self.effectView.removeFromSuperview()
                            }
                            
                        }
                        completion("done")
                    }
                    else{
                        DispatchQueue.main.async{
                            self.handleCloudSyncCompletionError(type: type)
                        }
                        completion("done")
                    }
                }
            }
            else{
                completion("done")
            }
        }
    }
    
    func handleCloudSyncCompletionError(type : String){
        self.effectView.removeFromSuperview()
        if(type == "notAuthenticated"){
            self.showChangeTokenErrorAlert()
        }
        else if(type == "networkUnavailable"){
            let alertTitle = NSLocalizedString("Network Unavailable", comment: "iCloud Sync Error - most likely caused by a network being unavailable")
            let alertMessage = NSLocalizedString("The app is unable to connect to the internet and thus won't be able to function correctly. Please ensure appropriate connectivity", comment: "iCloud Sync Error - most likely caused by wifi or mobile data being unavailable")
            let okButton = NSLocalizedString("OK", comment: "OK")
            self.showErrorAlert(alertTitle : alertTitle, alertMessage : alertMessage, okButton : okButton)
        }
        else if(type == "networkFailure"){
            let alertTitle = NSLocalizedString("Network Failure", comment: "iCloud Sync Error - most likely caused by a network failure")
            let alertMessage = NSLocalizedString("The app is unable to connect to the internet and thus won't be able to function correctly. Please ensure appropriate connectivity", comment: "iCloud Sync Error - most likely caused by wifi or mobile data being unavailable")
            let okButton = NSLocalizedString("OK", comment: "OK")
            self.showErrorAlert(alertTitle : alertTitle, alertMessage : alertMessage, okButton : okButton)
        }
        else{
            print("unhandled cloud sync completion error \(type)")
        }
    }
    
    func showChangeTokenErrorAlert(){
        let alertTitle = NSLocalizedString("iCloud Required", comment: "iCloud Sync Error - most likely caused by invalid change token")
        let alertMessage = NSLocalizedString("You are not logged into iCloud or removed iCloud priviledges for OAHelper. Would you like to disable iCloud Sync?", comment: "iCloud Sync Error - most likely caused by invalid change token")
        
        let okButton = NSLocalizedString("Yes", comment: "yes")
        let cancelButton = NSLocalizedString("No", comment: "No")
        
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButton, style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            print("I will disable iCoud Syning now")
            self.settings.setSettingsValue(value: false, key: "bookmarks_icloud")
            
        }))
        alert.addAction(UIAlertAction(title: cancelButton, style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            print("you have pressed the Cancel button")
            self.activeBookMarkCheck = true
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showCloudSyncMessage(){
        let message = NSLocalizedString("Updating iCloud Bookmarks", comment: "iCloud Bookmark Sync - shows as tapped")
        activityIndicator(message)
    }
    
    func networkAvailable(){
        let monitor = NWPathMonitor()
        
        monitor.pathUpdateHandler = { path in
            if path.availableInterfaces.count == 0 {
                DispatchQueue.main.async {
                    self.isOnline = false
                    //self.offlineLabel.text = "offline"
                }
            }
            else{
                DispatchQueue.main.async {
                    self.isOnline = true
                    //self.offlineLabel.text = ""
                    if(self.settings.getSettingsValue(key: "bookmarks_icloud")){
                        //self.syncButton.isHidden = false
                    }
                }
                
            }
        }
        
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
    }
    
    func showErrorAlert(alertTitle : String, alertMessage : String, okButton : String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButton, style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            //self.syncButton.isHidden = true
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func activityIndicator(_ title: String) {
        
        strLabel.removeFromSuperview()
        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()
        let width = 275
        let height = 75
        let height2 = height + (height/3*2)
        
        strLabel = UILabel(frame: CGRect(x: 0, y: 35, width: width, height: height))
        strLabel.text = title
        strLabel.font = .systemFont(ofSize: 14, weight: .medium)
        strLabel.textColor = UIColor(white: 0.9, alpha: 0.7)
        strLabel.textAlignment = .center;
        
        effectView.frame = CGRect(x: view.frame.midX - CGFloat(width/2), y: view.frame.midY - CGFloat(height*2) , width: CGFloat(width), height: CGFloat(height2))
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true
        
        activityIndicator = UIActivityIndicatorView(style: .white)
        activityIndicator.frame = CGRect(x: width/2-23, y: 15, width: 46, height: 46)
        activityIndicator.startAnimating()
        
        effectView.contentView.addSubview(activityIndicator)
        effectView.contentView.addSubview(strLabel)
        view.addSubview(effectView)
        self.view.layoutIfNeeded()
        
        
    }
    
    func bookMarkSyncProcess(isRefresh: Bool){
        if(!isRefresh){
            self.showCloudSyncMessage()
        }
        self.activeBookMarkCheck = false
        self.bookMarkData.syncCloudChanges(){ (type : String) in
            if(type == "done"){
                DispatchQueue.main.async {
                    self.bookMarkCheck(isRefresh: isRefresh){ (type: String) in
                        if(type == "done"){
                            DispatchQueue.main.async {
                                if(!isRefresh){
                                    self.effectView.removeFromSuperview()
                                }
                                //print("removeFromSuperView")
                                self.bookMarkList = self.bookMarkData.getAllBookMarks()
                                self.tableView.reloadData()
                                self.settings.setSyncDate(type: "sync_date")
                                //print("tableView.reloadData")
                                if(isRefresh){
                                    self.tableView.refreshControl?.endRefreshing()
                                }
                            }
                        }
                    }
                }
            }
            else{
                DispatchQueue.main.async{
                    self.handleCloudSyncCompletionError(type: type)
                }
            }
        }
    }
    
    func cloudSync(isRefresh: Bool){
        if(!self.settings.getSettingsValue(key: "bookmarks_icloud")){
            print("not supposed to iCloud sync")
            return
        }
        if(!self.isOnline){
            let alertTitle = NSLocalizedString("Network Unavailable", comment: "iCloud Sync Error - most likely caused by a network being unavailable")
            let alertMessage = NSLocalizedString("The app is unable to connect to the internet and thus won't be able to function correctly. Please ensure appropriate connectivity", comment: "iCloud Sync Error - most likely caused by wifi or mobile data being unavailable")
            let okButton = "OK"
            self.showErrorAlert(alertTitle : alertTitle, alertMessage : alertMessage, okButton : okButton)
            return
        }
        if(self.settings.getSettingsValue(key: "reset_bookmarks_icloud")){
            self.bookMarkData.deleteAllBookmarks { (success : Bool) in
                if(success){
                    self.bookMarkList = []
                    self.tableView.reloadData()
                    self.settings.setEmptyChangeTokenData()
                    self.bookMarkSyncProcess(isRefresh: isRefresh)
                    self.settings.setSettingsValue(value: false, key: "reset_bookmarks_icloud")
                }
                else{
                    print("error that needs handling")
                }
            }
        }
        else{
            bookMarkSyncProcess(isRefresh: isRefresh)
        }
    }
    
    func showCloudSyncButton(){
        if(!self.settings.getSettingsValue(key: "bookmarks_icloud")){
            self.cloudSyncButton.tintColor = UIColor(red: 0.988, green: 0.631, blue: 0.216, alpha: 1.00);
        }
        else{
            self.cloudSyncButton.tintColor = UIColor.black
        }
    }
    
    @IBAction func cloudSyncTapped(_ sender: Any) {
        cloudSync(isRefresh: false)
    }
    
    
}
