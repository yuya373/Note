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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    var files = [Files.Metadata]()
    var path = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        print("path: \(path)")
        navigationItem.title = path == "" ? "/" : path
        
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        
        DropboxCache.instance.files(path: self.path) {
            self.files = $0.filter { f in !(DropboxCache.hasMedia(f)) }
            
            self.activityIndicatorView.stopAnimating()
            
            self.tableView.reloadData()
        }
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
        case "showFileDetail":
            guard let nav = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let vc = nav.visibleViewController as? FileDetailViewController else {
                fatalError("Unexpected vc: \(nav.visibleViewController)")
            }
            guard let cell = sender as? FileTableViewCell else {
                fatalError("Unexpected sender: \(sender ?? "")")
            }
            guard let indexPath = tableView.indexPath(for: cell) else {
                fatalError("indexPath is undefined.")
            }
            let file = files[indexPath.row]
            vc.file = file
        default:
            fatalError("Unexpected segue.")
        }
    }

}

extension ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("numberOfRows: \(files.count)")
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let file = files[indexPath.row]
        let isFolder = DropboxCache.isFolder(file)
        if (isFolder) {
            let id = "FolderTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: id) as? FolderTableViewCell else {
                fatalError("failed to dequeue cell.")
            }
            cell.file = file
            return cell
        } else {
            let id = "FileTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: id) as? FileTableViewCell else {
                fatalError("failed to dequeue cell.")
            }
            cell.file = file
            return cell
        }
    }
}

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = files[indexPath.row]
        let isFolder = DropboxCache.isFolder(file)
        if (isFolder) {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "ListViewController") as? ListViewController,
                let path = file.pathLower {
                vc.path = path
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "FileDetailViewController") as? FileDetailViewController {
                vc.file = file
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
