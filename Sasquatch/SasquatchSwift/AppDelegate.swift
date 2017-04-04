import UIKit

import MobileCenter
import MobileCenterAnalytics
import MobileCenterCrashes
import MobileCenterDistribute

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MSCrashesDelegate {
  
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    // Start Mobile Center SDK.
    MSMobileCenter.setLogLevel(MSLogLevel.verbose)
    MSMobileCenter.start("0dbca56b-b9ae-4d53-856a-7c2856137d85", withServices: [MSAnalytics.self, MSCrashes.self, MSDistribute.self])
    
    // Crashes Delegate.
    MSCrashes.setUserConfirmationHandler({ (errorReports: [MSErrorReport]) in
      
      // Your code.
      // Present your UI to the user, e.g. an UIAlertView.
      
      let alert = MSAlertController(title: "Sorry about that!",
                                    message: "Do you want to send an anonymous crash report so we can fix the issue?")
      alert?.addDefaultAction(withTitle: "Send", handler: { (alert) in
        MSCrashes.notify(with: MSUserConfirmation.send)
      })
      alert?.addDefaultAction(withTitle: "Always Send", handler: { (alert) in
        MSCrashes.notify(with: MSUserConfirmation.always)
      })
      alert?.addCancelAction(withTitle: "Don't Send", handler: { (alert) in
        MSCrashes.notify(with: MSUserConfirmation.dontSend)
      })
      alert?.show()
      return true
    })
    
    setMobileCenterDelegate()
    
    return true
  }
  
  private func setMobileCenterDelegate(){
    let sasquatchController = (window?.rootViewController as! UINavigationController).topViewController as! MSMainViewController
    sasquatchController.mobileCenter = MobileCenterDelegateSwift()
  }
  
  /**
   *  This addition is required in case apps support iOS 8. Apps that are iOS 9 and later don't need to implement this
   * as our SDK uses SFSafariViewController for MSDistribute.
   */
  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    
    // Forward the URL to MSDistribute.
    MSDistribute.open(url as URL!)
    return true
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
  
  // Crashes Delegate
  
  func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
    return true;
    // return true if the crash report should be processed, otherwise false.
  }
  
  func crashes(_ crashes: MSCrashes!, willSend errorReport: MSErrorReport!) {
    
  }
  
  func crashes(_ crashes: MSCrashes!, didSucceedSending errorReport: MSErrorReport!) {
    
  }
  
  func crashes(_ crashes: MSCrashes!, didFailSending errorReport: MSErrorReport!, withError error: Error!) {
    
  }
}

