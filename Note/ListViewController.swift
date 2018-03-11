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
    var files = [File]()
    var folders = [Folder]()
    var path = ""
    var refreshControl: UIRefreshControl!
    
    enum OpType {
        case browse
        case bookmark
    }
    
    var opType = OpType.browse

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        print("path: \(path)")
        navigationItem.title = path == "" ? "/" : path
        if (opType == .browse) {
            navigationItem.prompt = "Add folder to Menu"
        } else {
            navigationItem.rightBarButtonItem = nil
        }

        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        
        loadData(expireCache: false)
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ListViewController.handleRefresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    private func loadData(expireCache: Bool = false) {
        DropboxCache.instance.files(path: self.path, refresh: expireCache) {
            self.files = $0.sorted { a, b in a.serverModified! > b.serverModified! }
            self.folders = $1
            
            self.activityIndicatorView.stopAnimating()
            
            self.tableView.reloadData()
        }
    }
    
    @objc func handleRefresh(_: Any) {
        loadData(expireCache: true)
        refreshControl.endRefreshing()
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
    }

    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        tabBarController.flatMap { $0 as? UITabBarViewController }.map { tabBarController in
            tabBarController.addBookmark(path: self.path, select: true)
            TabManager.updateBookmark(path: self.path)
        }
    }
}

extension ListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Folders"
        }
        return "Files"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return folders.count
        }
        return files.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isFolder = indexPath.section == 0
        
        if (isFolder) {
            let id = "FolderTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: id) as? FolderTableViewCell else {
                fatalError("failed to dequeue cell.")
            }
            let file = folders[indexPath.row]
            cell.file = file
            return cell
        } else {
            let id = "FileTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: id) as? FileTableViewCell else {
                fatalError("failed to dequeue cell.")
            }
            let file = files[indexPath.row]
            cell.file = file
            return cell
        }
    }
}

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let isFolder = indexPath.section == 0
        
        if (isFolder) {
            let file = folders[indexPath.row]
            if let vc = storyboard?.instantiateViewController(withIdentifier: "ListViewController") as? ListViewController,
                let path = file.pathLower {
                vc.path = path
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "FileDetailViewController") as? FileDetailViewController {
                let file = files[indexPath.row]
                vc.file = file
                navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let isFolder = indexPath.section == 0
        if (isFolder) {
            print("Folder accessoryButton Tapped")
        } else {
            print("File accessoryButton Tapped")
            let file = files[indexPath.row]
            let message = file.description_
            let alert = UIAlertController(title: file.pathDisplay, message: message, preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }
    }
}
