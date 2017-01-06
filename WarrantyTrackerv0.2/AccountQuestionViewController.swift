//
//  AccountQuestionViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-01-05.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class AccountQuestionViewController: UIViewController {
    
    var signingIn = false
    
    @IBAction func skipButtonPressed(_ sender: UIButton) {
        // set userdefaults for first launch
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "FirstLaunch")
    }
    
    @IBAction func yesButtonPressed(_ sender: UIButton) {
        signingIn = true
        
        self.performSegue(withIdentifier: "toSignUpController", sender: nil)
    }
    
    @IBAction func noButtonPressed(_ sender: UIButton) {
        signingIn = false
        
        self.performSegue(withIdentifier: "toSignUpController", sender: nil)
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        
    }
    
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toSignUpController") {
            if let nextViewController = segue.destination as? SignUpViewController {
                nextViewController.signingIn = signingIn
            }
        }
    }
}
