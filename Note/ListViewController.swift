//
//  ListViewController.swift
//  Note
//
//  Created by 南優也 on 2018/03/10.
//  Copyright © 2018年 南優也. All rights reserved.
//

import UIKit
import SwiftyDropbox

class ListViewController: UIViewController {
    var files = [Files.Metadata]()

    override func viewDidLoad() {
        super.viewDidLoad()

        DropboxCache.instance.files {
            self.files = $0
            self.files.map { file in
                print("\(file.name), \(file.description)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
