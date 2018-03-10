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
    var files = [Files.Metadata]()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        navigationItem.title = "Dropbox/"
        DropboxCache.instance.files(path: "") {
            print("files: \($0.count)")
            self.files = $0.filter(DropboxCache.folderOrMarkDownOrOrg)
            print("files: \(self.files.count)")
            self.tableView.reloadData()
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

extension ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("numberOfRows: \(files.count)")
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let file = files[indexPath.row]
        let id = "FileTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: id) as? FileTableViewCell else {
            fatalError("failed to dequeue cell.")
        }
        cell.titleLabel.text = file.name
        if (DropboxCache.isFolder(file)) {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.accessoryType = .detailDisclosureButton
        }
        return cell
    }
}

extension ListViewController: UITableViewDelegate {
}
