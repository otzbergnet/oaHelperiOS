//
//  ZoteroTableViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 17.04.21.
//  Copyright © 2021 Claus Wolf. All rights reserved.
//

import UIKit
import SafariServices

class ZoteroTableViewController: UITableViewController {

    let zoteroAPI = ZoteroAPI()
    var zoteroItems = [ZoteroItem]()
    let settings = SettingsBundleHelper()
    
    var strLabel = UILabel()
    var activityIndicator = UIActivityIndicatorView()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Zotero Bookmarks"
        self.navigationItem.setHidesBackButton(true, animated: true)
        print(self.zoteroItems.count)
        self.doZoteroSync()
        
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.zoteroItems.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "zoteroBookmarkCell", for: indexPath) as! ZoteroTableViewCell

        let paper = self.zoteroItems[indexPath.row]
        let title = paper.data.title
        let journalTitle = paper.data.publicationTitle ?? ""
        let volume = paper.data.volume ?? ""
        let issue = paper.data.issue ?? ""
        let pages = paper.data.pages ?? ""
        let url = paper.data.url ?? ""
        var year = ""
        if let date = paper.data.date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            if let updatedAt = dateFormatter.date(from: date){
                dateFormatter.dateFormat = "(yyyy)"
                year = dateFormatter.string(from: updatedAt)
            }
        }
       
        var source = ""
        if journalTitle != "" {
            if journalTitle != "" {
                source += "\(journalTitle)"
            }
            if year != "" {
                source += " \(year)"
            }
            if volume != "" {
                source += " Vol. \(volume)"
            }
            if issue != "" {
                source += " Iss. \(issue)"
            }
            if pages != "" {
                source += ", p. \(pages)"
            }
        }
        else{
            source = "\(url)"
        }

        if(paper.data.itemType == "journalArticle") {
            cell.iconImageView.image = UIImage(named: "zarticle")
        }
        else if (paper.data.itemType == "webpage"){
            cell.iconImageView.image = UIImage(named: "zwebpage")
        }
        else if (paper.data.itemType == "attachment"){
            cell.iconImageView.image = UIImage(named: "zclip")
        }
        
        cell.titleLabel.text = title
        cell.detailLabel.text = source
        return cell

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let myurl = self.zoteroItems[indexPath.row].data.url {
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

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let itemId = indexPath.row
            let key = self.zoteroItems[itemId].key
            let version = self.zoteroItems[itemId].version
            zoteroAPI.deleteZoteroItem(key: key, version: version) { (res) in
                switch(res){
                case .success(let success):
                    if(success){
                        DispatchQueue.main.async {
                            self.zoteroItems.remove(at: indexPath.row)
                            tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    }
                    else{
                        DispatchQueue.main.async {
                            let alertTitle = NSLocalizedString("Error", comment: "shown when zotero item could not be deleted")
                            let alertMessage = NSLocalizedString("Something went wrong, while we attempted to delete the item. Please try again and contact me, if this happens again", comment: "shown when zotero item could not be deleted")
                            self.showErrorAlert(alertTitle: alertTitle, alertMessage: alertMessage, okButton: "OK")
                        }
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    

    func showErrorAlert(alertTitle : String, alertMessage : String, okButton : String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButton, style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            //self.syncButton.isHidden = true
        }))
        self.present(alert, animated: true, completion: nil)
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
    
    func doZoteroSync() {
        DispatchQueue.main.async {
            self.activityIndicator("Getting Bookmarks from Zotero")
        }
        zoteroAPI.getZoteroItems(name: "test") { (res) in
            switch(res) {
            case .success(let data):
                self.zoteroItems = data
                DispatchQueue.main.async {
                    self.effectView.removeFromSuperview()
                    self.tableView.reloadData()
                }
            case .failure(let error):
                var errorMessage = NSLocalizedString("An unknown error occured", comment: "shown getZoteroItems error")
                let errorTitle = NSLocalizedString("Zotero API error", comment: "shown getZoteroItems error")
                switch(error.code){
                case 403:
                    // 403 forbidden, the API key is gone or invalid
                    self.settings.setSettingsValue(value: false, key: "zotero")
                    self.settings.setSettingsStringValue(value: "", key: "userID")
                    self.settings.setSettingsStringValue(value: "", key: "oauth_token")
                    self.settings.setSettingsStringValue(value: "", key: "collectionID")
                    // show error message
                    errorMessage = NSLocalizedString("Zotero informed us that your API key is no longer valid. You will need to reauthenticate", comment: "shown getZoteroItems error")
                case 404:
                    // 404 not found, the collection is not there or the user id is invalid best to reset
                    self.settings.setSettingsValue(value: false, key: "zotero")
                    self.settings.setSettingsStringValue(value: "", key: "userID")
                    self.settings.setSettingsStringValue(value: "", key: "oauth_token")
                    self.settings.setSettingsStringValue(value: "", key: "collectionID")
                    // show error message
                    errorMessage = NSLocalizedString("Access your data was not possible. I've disabled the Zotero integration and recommend that you re-authenticate.", comment: "shown getZoteroItems error")
                case 429:
                    errorMessage = NSLocalizedString("Apparently we made too many request - please pause your activity for a little while and try again much later", comment: "shown getZoteroItems error")
                case 500:
                    errorMessage = NSLocalizedString("Zotero encountered an Intern Server Error - please try again later", comment: "shown getZoteroItems error")
                case 503:
                    errorMessage = NSLocalizedString("Zotero is currently unable to handle your request - please try again later", comment: "shown getZoteroItems error")
                default:
                    errorMessage = NSLocalizedString("An unknown error occured - please try again later", comment: "shown getZoteroItems error")
                    errorMessage += "\n\n\(error.localizedDescription) \(error.code)"
                }
                DispatchQueue.main.async {
                    self.effectView.removeFromSuperview()
                    self.showErrorAlert(alertTitle : errorTitle, alertMessage : errorMessage, okButton : "OK")
                }
            }
        }
    }
}
