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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Zotero Bookmarks"
        self.navigationItem.setHidesBackButton(true, animated: true)

        zoteroAPI.getZoteroItems(name: "test") { (res) in
            switch(res) {
            case .success(let data):
                self.zoteroItems = data
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
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

}
