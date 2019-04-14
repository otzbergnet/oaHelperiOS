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
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accessButton: UIButton!
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var abstractNewLabel: UITextView!
    
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var pdfButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    
    var blueColor = UIColor(displayP3Red: 0.102, green: 0.596, blue: 0.988, alpha: 1.00)
    var greenColor = UIColor(displayP3Red: 0, green: 143/255, blue: 0, alpha: 1.00)
    var orangeColor = UIColor(displayP3Red: 252/255, green: 156/255, blue: 44/255, alpha: 1.00) // wrong
    var redColor = UIColor(displayP3Red: 177/255, green: 30/255, blue: 34/255, alpha: 1.00)
    
    var coreRecords = [Items]()
    var num : Int = 0
    var url : String = ""
    var pdf : Bool = false
    
    var hc = HelperClass()
    let settings = SettingsBundleHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        accessButton.layer.cornerRadius = 10
        createDetailData(num: self.num)
        self.title = "\(self.num+1)/\(self.coreRecords.count)"
    }
    

    override func viewDidLayoutSubviews() {
        //resizeView()
    }
    
    // MARK: - Data Handling
    
    func createDetailData(num : Int){
        let detailData = DetailData()
        detailData.title = self.coreRecords[num].title ?? ""
        detailData.author = self.coreRecords[num].authors ?? []
        detailData.abstract = self.coreRecords[num].description ?? ""
        detailData.num = num
        
        if let urls = self.coreRecords[num].downloadUrl{
            if(urls != ""){
                detailData.url = urls
                self.url = detailData.url
                detailData.buttonLabel = NSLocalizedString("Access Full Text", comment: "button, access full text")
            }
            else{
                var arxivLink = ""
                if let arxiv = self.coreRecords[num].oai {
                    if arxiv.contains("oai:arXiv.org:"){
                        arxivLink = arxiv.replacingOccurrences(of: "oai:arXiv.org:", with: "https://arxiv.org/abs/")
                    }
                }
                
                if(arxivLink != ""){
                    detailData.url = arxivLink
                    self.url = detailData.url
                    detailData.buttonLabel = NSLocalizedString("View Record at arXiv.org", comment: "button, arXiv.org document")
                }
                else if let id = self.coreRecords[num].id{
                    detailData.url = "https://core.ac.uk/display/\(id)"
                    self.url = detailData.url
                    detailData.buttonLabel = NSLocalizedString("View Record at core.ac.uk", comment: "button, core.ac.uk document")
                }
                else{
                    detailData.url = ""
                    self.url = detailData.url
                }
                
            }
        }
        
        createRecord(coreRecord: detailData)
        changeNavButtonColor(num: num)
    }
    
    func createRecord(coreRecord: DetailData){
        
        titleLabel.text = coreRecord.title
        let byText = NSLocalizedString("By: ", comment: "By is shown just before authors")
        if(coreRecord.author.count > 0){
            if(coreRecord.author.count > 3){
                authorLabel.text = "\(byText) \(coreRecord.author[0]), \(coreRecord.author[1]), et al."
            }
            else if(coreRecord.author.count > 1){
                authorLabel.text = "\(byText) \(coreRecord.author[0]), \(coreRecord.author[1])"
            }
            else{
                authorLabel.text = "\(byText) \(coreRecord.author[0])"
            }
            
        }
        else{
            authorLabel.text = ""
        }
        
        abstractNewLabel.text = hc.cleanAbstract(txt: coreRecord.abstract)
        abstractNewLabel.sizeToFit()
        accessButton.setTitle(coreRecord.buttonLabel, for: .normal)
        let label = NSLocalizedString("View Record at core.ac.uk", comment: "in this case used for string comparison")
        if(coreRecord.buttonLabel == label){
            accessButton.backgroundColor = blueColor
            pdfButton.backgroundColor = blueColor
            pdfButton.setTitle("core.ac.uk", for: .normal)
            self.pdf = false
        }
        else if (coreRecord.buttonLabel.contains("arXiv.org")){
            accessButton.backgroundColor = redColor
            pdfButton.backgroundColor = greenColor
            pdfButton.setTitle("arXiv.org", for: .normal)
            self.pdf = false
        }
        else{
            accessButton.backgroundColor = greenColor
            pdfButton.backgroundColor = greenColor
            pdfButton.setTitle("PDF", for: .normal)
            self.pdf = true
        }
        if(coreRecord.url == "" ){
            self.pdf = false
            accessButton.isHidden = true
        }
        
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
            self.title = "\(self.num+1)/\(self.coreRecords.count)"
        }
    }
    
    func goNext(){
        let next = self.num+1
        if(next < coreRecords.count){
            scrollToTop()
            createDetailData(num: next)
            self.num = next
            self.title = "\(self.num+1)/\(self.coreRecords.count)"
        }
    }
    
    func changeNavButtonColor(num: Int){
        if(num == 0){
            previousButton.setTitleColor(orangeColor, for: .normal)
            nextButton.setTitleColor(.white, for: .normal)
        }
        else if(num == coreRecords.count-1){
            previousButton.setTitleColor(.white, for: .normal)
            nextButton.setTitleColor(orangeColor, for: .normal)
        }
        else{
            previousButton.setTitleColor(.white, for: .normal)
            nextButton.setTitleColor(.white, for: .normal)
        }
    }
    
  
    // MARK: - Action Buttons


    @IBAction func accessTapped(_ sender: Any) {
        goToDocument()
    }
    
    @IBAction func previousTapped(_ sender: Any) {
        goPrevious()
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        goNext()
    }
    
    @IBAction func pdfTapped(_ sender: Any) {
        goToDocument()
    }
    

}
