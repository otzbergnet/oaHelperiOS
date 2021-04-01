//
//  DetailViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 16.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import UIKit
import SafariServices

class DetailData{
    var title : String = ""
    var author = [String]()
    var abstract : String = ""
    var url : String = ""
    var buttonLabel = ""
    var num : Int = 0
}

class DetailViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var abstractNewLabel: UITextView!
    
    // MARK: Buttons
    
    @IBOutlet weak var accessButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var pdfButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    let selection = UISelectionFeedbackGenerator()
    let impact = UIImpactFeedbackGenerator()
    
    var blueColor = UIColor(displayP3Red: 0.102, green: 0.596, blue: 0.988, alpha: 1.00)
    var greenColor = UIColor(displayP3Red: 0, green: 143/255, blue: 0, alpha: 1.00)
    var orangeColor = UIColor(displayP3Red: 252/255, green: 156/255, blue: 44/255, alpha: 1.00) // wrong
    var redColor = UIColor(displayP3Red: 177/255, green: 30/255, blue: 34/255, alpha: 1.00)
    
    var searchResults = SearchResult()
    var num : Int = 0
    var url : String = ""
    var pdf : Bool = false
    
    var hc = HelperClass()
    let settings = SettingsBundleHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        accessButton.layer.cornerRadius = 10
        createDetailData(num: self.num)
        
        AppStoreReviewManager.requestReviewIfAppropriate()
        
        if #available(iOS 13.4, *) {
            accessButton.isPointerInteractionEnabled = true
            previousButton.isPointerInteractionEnabled = true
            nextButton.isPointerInteractionEnabled = true
            pdfButton.isPointerInteractionEnabled = true
        }
    }
    

    override func viewDidLayoutSubviews() {
        //resizeView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    // MARK: - Data Handling
    
    func createDetailData(num : Int){
        self.title = "\(self.num+1)/\(self.searchResults.records.count)"
        titleLabel.text = searchResults.records[num].title
        let byText = NSLocalizedString("By: ", comment: "By is shown just before authors")
        if(searchResults.records[num].author != ""){
            authorLabel.text = "\(byText) \(searchResults.records[num].author)"
        }
        else{
            authorLabel.text = ""
        }
        abstractNewLabel.text = hc.cleanAbstract(txt: searchResults.records[num].abstract)
        abstractNewLabel.sizeToFit()
        accessButton.setTitle(searchResults.records[num].buttonLabel, for: .normal)
        self.url = searchResults.records[num].linkUrl
//        let label = NSLocalizedString("View Record at core.ac.uk", comment: "in this case used for string comparison")
//        if(coreRecord.buttonLabel == label){
//            accessButton.backgroundColor = blueColor
//            pdfButton.backgroundColor = blueColor
//            pdfButton.setTitle("core.ac.uk", for: .normal)
//            self.pdf = false
//        }
//        else if (coreRecord.buttonLabel.contains("arXiv.org")){
//            accessButton.backgroundColor = redColor
//            pdfButton.backgroundColor = greenColor
//            pdfButton.setTitle("arXiv.org", for: .normal)
//            self.pdf = false
//        }
//        else{
//            accessButton.backgroundColor = greenColor
//            pdfButton.backgroundColor = greenColor
//            pdfButton.setTitle("PDF", for: .normal)
//            self.pdf = true
//        }
//        if(coreRecord.url == "" ){
//            self.pdf = false
//            accessButton.isHidden = true
//        }
//
        
        changeNavButtonColor(num: num)
    }




// MARK: - Page Navigation Buttons

func scrollToTop(){
    let desiredOffset = CGPoint(x: 0, y: -self.scrollView.contentInset.top)
    self.scrollView.setContentOffset(desiredOffset, animated: false)
}



func goToDocument(){

    if(self.url != ""){
        //print(coreRecord.url)
        if(self.pdf){
            self.settings.incrementOACount(key : "core_pdf")
        }
        let url = URL(string: self.url.trimmingCharacters(in: .whitespacesAndNewlines))
        let vc = SFSafariViewController(url: url!)
        self.present(vc, animated: true, completion: nil)
    }
    else{
        print("access Tapped failed somehow - empty?")
    }
}

func goPrevious(){
    let previous = self.num - 1
    if(previous != -1){
        scrollToTop()
        createDetailData(num: previous)
        self.num = previous
        self.title = "\(self.num+1)/\(self.searchResults.records.count)"
    }
}

func goNext(){
    let next = self.num+1
    if(next < self.searchResults.records.count){
        scrollToTop()
        createDetailData(num: next)
        self.title = "\(self.num+1)/\(self.searchResults.records.count)"
        self.num = next
    }
}

func changeNavButtonColor(num: Int){
    if(num == self.searchResults.records.count-1 && num == 0){
        previousButton.setTitleColor(orangeColor, for: .normal)
        nextButton.setTitleColor(orangeColor, for: .normal)
    }
    else if(num == self.searchResults.records.count-1){
        previousButton.setTitleColor(.white, for: .normal)
        nextButton.setTitleColor(orangeColor, for: .normal)
    }
    else if(num == 0){
        previousButton.setTitleColor(orangeColor, for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
    }
    else{
        previousButton.setTitleColor(.white, for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
    }
}


// MARK: - Action Buttons


@IBAction func accessTapped(_ sender: Any) {
    impact.impactOccurred()
    goToDocument()
}

@IBAction func previousTapped(_ sender: Any) {
    selection.selectionChanged()
    goPrevious()
}

@IBAction func nextTapped(_ sender: Any) {
    selection.selectionChanged()
    goNext()
}

@IBAction func pdfTapped(_ sender: Any) {
    impact.impactOccurred()
    goToDocument()
}

@IBAction func swipedLeft(_ sender: Any) {
    selection.selectionChanged()
    goNext()
}

@IBAction func swipedRight(_ sender: Any) {
    selection.selectionChanged()
    goPrevious()
}


}
