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

class BookmarkTableViewController: UITableViewController {

    var bookMarkList : [BookMark] = []
    var bookMarkData = BookMarkData()


    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.title = "Bookmarks"
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
    }
    
    @objc func refreshData(refreshControl: UIRefreshControl) {
        self.bookMarkList = self.bookMarkData.getAllBookMarks()
        tableView.reloadData()
        // somewhere in your code you might need to call:
        self.bookMarkData.syncAllBookmarks()
        refreshControl.endRefreshing()
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
            print("this record: \(String(describing: self.bookMarkList[indexPath.row].title)) needs to be synced")
        }
        if(self.bookMarkList[indexPath.row].title != ""){
           cell.textLabel?.text = self.bookMarkList[indexPath.row].title
        }
        else{
            cell.textLabel?.text = "-"
        }
        
        if(self.bookMarkList[indexPath.row].pdf != ""){
           cell.detailTextLabel?.text = self.bookMarkList[indexPath.row].pdf
        }
        else{
            cell.detailTextLabel?.text = self.bookMarkList[indexPath.row].url
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
