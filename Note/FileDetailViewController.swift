//
//  FileDetailViewController.swift
//  Note
//
//  Created by 南優也 on 2018/03/11.
//  Copyright © 2018年 南優也. All rights reserved.
//

import UIKit
import SwiftyDropbox
import WebKit

class FileDetailViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    var file: File?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        activityIndicatorView.hidesWhenStopped = true
        
        webView.navigationDelegate = self

        file.map { file in
            if ((file.name ?? "").hasSuffix(".org")) {
                let url = Bundle.main.url(forResource: "org", withExtension: "html")!
                let req = URLRequest(url: url)
                webView.load(req)
            } else {
                let url = Bundle.main.url(forResource: "md", withExtension: "html")!
                let req = URLRequest(url: url)
                webView.load(req)
            }
            navigationItem.title = file.name
            self.activityIndicatorView.startAnimating()
            
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

extension FileDetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let file = self.file {
            DropboxClientsManager.authorizedClient?.files.download(path: file.pathLower!).response { (result, error) in
                result.map {
                    let (_, data) = $0
                    if let str = String(bytes: data, encoding: String.Encoding.utf8) {
                        let exp = str.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "'", with: "\\'").components(separatedBy: .newlines).joined(separator: "\\n")
                        let js = """
                            try {
                                insert('\(exp)');
                            } catch(e) {
                                alert(e);
                            }
                        """
                        
                        print("str: \(exp)")
                        webView.evaluateJavaScript(js, completionHandler: { result, error in
                            result.map { print("result: \($0)") }
                            error.map { print("error: \($0)") }
                        })
                    }
                }
                error.map {
                    fatalError("failed to download file: \(file.pathLower ?? "no pathLower!"), error: \($0.description)")
                }
                
                self.activityIndicatorView.stopAnimating()
            }
        }
    }
    
}
