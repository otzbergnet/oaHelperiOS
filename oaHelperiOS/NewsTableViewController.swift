//
//  NewsTableViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 27.04.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit

class NewsTableViewController: UITableViewController {
    
    var newsItemsToShow : [NewsItemItem] = []
    let newsItemData = NewsItemData()
    let helper = HelperClass()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        newsItemsToShow = newsItemData.getAllNewsItems()
        self.updateUnreadCount();
        
        newsItemData.getNews(forced: false) { ( res) in
            switch res {
            case .success(_):
                DispatchQueue.main.async {
                    self.newsItemsToShow = self.newsItemData.getAllNewsItems()
                    self.tableView.reloadData()
                    self.updateUnreadCount();
                }
            case .failure(let error):
                print("failed to fetch newsItems:", error)
            }
        }
        
        let refreshControl = UIRefreshControl()
        let title = NSLocalizedString("Updating News Items", comment: "RefreshControl")
        refreshControl.attributedTitle = NSAttributedString(string: title)
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        newsItemsToShow = newsItemData.getAllNewsItems()
        self.tableView.reloadData()
        self.updateUnreadCount();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    @objc func refreshData(refreshControl: UIRefreshControl) {
        newsItemData.getNews(forced: true) { ( res) in
            switch res {
            case .success(_):
                DispatchQueue.main.async {
                    self.newsItemsToShow = self.newsItemData.getAllNewsItems()
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                    self.updateUnreadCount();
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                    print("failed to fetch newsItems:", error)
                }
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
        //print(self.newsItemsToShow.count)
        return self.newsItemsToShow.count
    }
    
    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath)
         // Configure the cell...
            //print(self.newsItemsToShow[indexPath.row].title)
        var indicator = ""
        if(!self.newsItemsToShow[indexPath.row].read){
            indicator = "★ "
        }
        let title = self.newsItemsToShow[indexPath.row].title
        
        if (title != ""){
            cell.textLabel!.text = indicator + title
        }
        else{
            cell.textLabel!.text = indicator + "-"
        }
        
        cell.detailTextLabel!.text = self.newsItemsToShow[indexPath.row].body
         return cell
     }
    
    /*
 override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
 tableView.deselectRow(at: indexPath, animated: true)
 let countryData = self.allCountryData[indexPath.row]
 //let plane = self.planes[indexPath.row]
 self.performSegue(withIdentifier: "tableToDetail", sender: countryData)
 }
 
 override func prepare(for segue: UIStoryboardSegue?, sender: Any?) {
 if (segue?.identifier == "tableToDetail") {
 let countryData = sender as! Country
 let detailViewData = segue?.destination as! DetailViewController
 detailViewData.countryData = countryData
 }
 }
 */
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let myNewsItem : NewsItemItem = self.newsItemsToShow[indexPath.row]
        self.performSegue(withIdentifier: "detailNewsSegue", sender: myNewsItem)
    }
 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "detailNewsSegue" {
            let myNewsItem = sender as? NewsItemItem
            if let nextViewController = segue.destination as? DetailNewsViewController {
                nextViewController.newsItem = myNewsItem
            }
        }
    }

    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
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
    
    func updateUnreadCount(){
        let unreadCount = self.newsItemData.getUnreadCount();
        if let tabBar = self.tabBarController{
            self.helper.updateTabBar(tabBarController: tabBar, value: "\(unreadCount)")
        }
    }
    
    
    
}


