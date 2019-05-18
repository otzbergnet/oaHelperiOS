//
//  DetailNewsViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 03.05.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit

class DetailNewsViewController: UIViewController {

    var newsItem : NewsItemItem?
    let newsData = NewsItemData()

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var bodyText: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if let myNewsItem = newsItem{
            titleLabel.text = myNewsItem.title
            dateLabel.text = myNewsItem.date
            bodyText.text = myNewsItem.body
            
            if(!myNewsItem.read){
                self.newsData.markRead(requestId: myNewsItem.id)
            }
        }
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bodyText.setContentOffset(CGPoint.zero, animated: false)
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
