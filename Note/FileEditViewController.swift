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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        nameTextField.text = file.name
        dataTextView.text = dataAsString
        
        let color = UIColor(red: 186/255, green: 186/255, blue: 186/255, alpha: 1.0).cgColor
        dataTextView.layer.borderColor = color
        dataTextView.layer.borderWidth = 0.5
        dataTextView.layer.cornerRadius = 5.0

        // registerObserver()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // removeObserver()
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
    
    // MARK: - Actions

    @IBAction func cancelDataTextView(_ sender: UITapGestureRecognizer) {
        if (dataTextView.isFirstResponder) {
            dataTextView.resignFirstResponder()
        }
    }

    // MARK: - Private Methods
    
    private func registerObserver() {
        let notification = NotificationCenter.default
        notification.addObserver(self, selector: #selector(FileEditViewController.keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        notification.addObserver(self, selector: #selector(FileEditViewController.keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    private func removeObserver() {
        let notification = NotificationCenter.default
        notification.removeObserver(self)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if (!dataTextView.isFirstResponder) {
            return
        }
        if let rect = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSValue) as? Double {
            UIView.animate(withDuration: duration, animations: {
                let transform = CGAffineTransform(translationX: 0, y: -rect.size.height)
                self.view.transform = transform
            })
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if (!dataTextView.isFirstResponder) {
            return
        }
        if let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSValue) as? Double {
            UIView.animate(withDuration: duration, animations: {
                self.view.transform = CGAffineTransform.identity
            })
        }
    }
}
