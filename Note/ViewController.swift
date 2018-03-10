//
//  ViewController.swift
//  Note
//
//  Created by 南優也 on 2018/03/09.
//  Copyright © 2018年 南優也. All rights reserved.
//

import UIKit
import SwiftyDropbox

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        if (DropboxClientsManager.authorizedClient != nil) {
            let id = "AuthenticatedTop"
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: id) as? UITabBarController {
                UIApplication.shared.delegate?.window??.rootViewController?.present(vc, animated: false, completion: nil)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Actions
    @IBAction func authorize(_ sender: UIButton) {
            DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self, openURL: { UIApplication.shared.open($0) })

    }
}

