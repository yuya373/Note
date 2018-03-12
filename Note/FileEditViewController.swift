//
//  FileEditViewController.swift
//  Note
//
//  Created by 南優也 on 2018/03/12.
//  Copyright © 2018年 南優也. All rights reserved.
//

import UIKit

class FileEditViewController: UIViewController {
    var file: File!
    var dataAsString: String!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var dataTextView: UITextView!
    @IBOutlet weak var pesudoNavigationBar: UIView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        nameTextField.text = file.name
        dataTextView.text = dataAsString
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

    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
