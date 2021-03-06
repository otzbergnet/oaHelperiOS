//
//  AppDelegate.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 08.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window : UIWindow?
    var search = String()
    var proxy = String()
    let settings = SettingsBundleHelper()
    let helper = HelperClass()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Easy ay to determine whether we are going to show the onboarding or main user experience
        // at the end of onboarding the UserDefaults value for onBoarding will be set to true
        
        determineView()
        return true
    }
    
    // below function is used to receive data via URLscheme oahelper://
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let myUrl = "\(url)"
        print(myUrl)
        
        if let components = URLComponents(string: myUrl){
            if let queryItems = components.queryItems{
                if let myproxy = queryItems.filter({$0.name == "proxy"}).first{
                    if let base64data = myproxy.value{
                        if let data = Data(base64Encoded: base64data){
                            if let urlString = String(data: data, encoding: .utf8){
                                if(helper.validateProxyPrefix(urlString: urlString)){
                                    self.settings.setSettingsStringValue(value: urlString, key: "proxyPrefix")
                                    self.settings.setSettingsValue(value: true, key: "useProxy")
                                    self.proxy = urlString
                                }
                            }
                        }
                    }
                }
                if let instituteId = queryItems.filter({$0.name == "id"}).first{
                    if let id = instituteId.value{
                        self.settings.setSettingsStringValue(value: id, key: "instituteId")
                    }
                }
                if let mysearch = queryItems.filter({$0.name == "search"}).first{
                    self.search = mysearch.value ?? ""
                }
                if let oauth_token_tmp = queryItems.filter({$0.name == "oauth_token"}).first{
                    if let oauth_token = oauth_token_tmp.value {
                        self.settings.setSettingsStringValue(value: oauth_token, key: "oauth_token")
                        self.settings.setSettingsValue(value: true, key: "oauthreturn")
                    }
                }
                if let oauth_verifier_tmp = queryItems.filter({$0.name == "oauth_verifier"}).first{
                    if let oauth_verifier = oauth_verifier_tmp.value {
                        self.settings.setSettingsStringValue(value: oauth_verifier, key: "oauth_verifier")
                        self.settings.setSettingsValue(value: true, key: "oauthreturn")
                    }
                }
            }
        }
        determineView()
        return true
    }
    
    func determineView(){
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
        
        var mainStoryBoardVC : UIViewController
        var onboardingStoryBoardVC : UIViewController
        
        if(UserDefaults.standard.bool(forKey: "onBoarding")) == false {
            onboardingStoryBoardVC = onboardingStoryboard.instantiateInitialViewController()!
            self.window?.rootViewController = onboardingStoryBoardVC
            self.window?.makeKeyAndVisible()
        }
        else{
            mainStoryBoardVC = mainStoryboard.instantiateInitialViewController()!
            self.window?.rootViewController = mainStoryBoardVC
            self.window?.makeKeyAndVisible()
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    
    
}

