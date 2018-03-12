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
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var safariButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    var file: File!
    var fileDetailViewUrl: URL!
    var dataAsString: String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = file.name
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        activityIndicatorView.hidesWhenStopped = true
        
        editButton.isEnabled = false
        webView.navigationDelegate = self

        if ((file.name ?? "").hasSuffix(".org")) {
            self.fileDetailViewUrl = Bundle.main.url(forResource: "org", withExtension: "html")!
        } else {
            self.fileDetailViewUrl = Bundle.main.url(forResource: "md", withExtension: "html")!
        }
        
        let req = URLRequest(url: fileDetailViewUrl)
        webView.load(req)
        self.activityIndicatorView.startAnimating()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        switch segue.identifier ?? "" {
        case "editFile":
            guard let vc = segue.destination as? FileEditViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            vc.file = file
            vc.dataAsString = dataAsString ?? ""
        default:
            fatalError("Unexpected segue identifier: \(segue.identifier)")
        }
    }

    // MARK: - Actions
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        if (webView.canGoBack) {
            webView.goBack()
        }
    }
    
    @IBAction func forwardButtonTapped(_ sender: UIBarButtonItem) {
        if (webView.canGoForward) {
            webView.goForward()
        }
    }
    
    @IBAction func safariButtonTapped(_ sender: UIBarButtonItem) {
        if safariButton.isEnabled {
            if let url = webView.url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        if editButton.isEnabled {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "FileEditViewController") as? FileEditViewController {
                vc.file = file
                vc.dataAsString = dataAsString ?? ""
                navigationItem.title = nil
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

extension FileDetailViewController: WKNavigationDelegate {
    private func loadFileContents(webView: WKWebView) {
        DropboxClientsManager.authorizedClient?.files.download(path: file.pathLower!).response { (result, error) in
            result.map {
                let (_, data) = $0
                if let str = String(bytes: data, encoding: String.Encoding.utf8) {
                    self.dataAsString = str
                    self.editButton.isEnabled = true
                    
                    let exp = str.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "'", with: "\\'").components(separatedBy: .newlines).joined(separator: "\\n")
                    

                    let js = """
                        try {
                            insert('\(exp)');
                        } catch(e) {
                            alert(e);
                        }
                    """
                    
                    webView.evaluateJavaScript(js, completionHandler: { result, error in
                        result.map { print("result: \($0)") }
                        error.map { print("error: \($0)") }
                        
                    })
                }
            }
            error.map {
                fatalError("failed to download file: \(self.file.pathLower ?? "no pathLower!"), error: \($0.description)")
            }
            
            self.activityIndicatorView.stopAnimating()
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if (webView.url == self.fileDetailViewUrl) {
            loadFileContents(webView: webView)
            safariButton.isEnabled = false
            navigationItem.title = file.name
        } else {
            safariButton.isEnabled = true
            navigationItem.title = webView.title
            editButton.isEnabled = false
        }
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if navigationAction.navigationType == .linkActivated {
                if (navigationAction.targetFrame == nil || !navigationAction.targetFrame!.isMainFrame) {
                    webView.load(URLRequest(url: url))
                    decisionHandler(.cancel)
                    return
                }
            }
            
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }
}
