//
//  FileDetailViewController.swift
//  Note
//
//  Created by 南優也 on 2018/03/11.
//  Copyright © 2018年 南優也. All rights reserved.
//

import UIKit
import SwiftyDropbox

class FileDetailViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    var file: File?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        activityIndicatorView.hidesWhenStopped = true
        
        file.map { file in
            navigationItem.title = file.name
            self.activityIndicatorView.startAnimating()
            
            DropboxClientsManager.authorizedClient?.files.download(path: file.pathLower!).response { (result, error) in
                result.map {
                    let (meta, data) = $0
                    let str = String(bytes: data, encoding: String.Encoding.utf8)
                    self.textView.text = str ?? ""
                }
                error.map {
                    fatalError("failed to download file: \(file.pathLower ?? "no pathLower!"), error: \($0.description)")
                }

                self.activityIndicatorView.stopAnimating()
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
