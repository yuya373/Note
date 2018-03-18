//
//  FileEditViewController.swift
//  Note
//
//  Created by 南優也 on 2018/03/12.
//  Copyright © 2018年 南優也. All rights reserved.
//

import UIKit

class FileEditViewController: UIViewController {
    var file: File?
    var directory: String?
    var dataAsString: String!
    var reloadFile: (() -> Void)?
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var dataTextView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardObserver()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.title = file?.name

        nameTextField.text = file?.name
        nameTextField.delegate = self
        saveButton.isEnabled = saveButtonIsEnabled()
        
        dataTextView.text = dataAsString
        let color = UIColor(red: 186/255, green: 186/255, blue: 186/255, alpha: 1.0).cgColor
        dataTextView.layer.borderColor = color
        dataTextView.layer.borderWidth = 0.5
        dataTextView.layer.cornerRadius = 5.0
        
        activityIndicatorView.hidesWhenStopped = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObserver()
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
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        saveButton.isEnabled = false
        activityIndicatorView.startAnimating()
        let str = dataTextView.text ?? ""

        if let data = str.data(using: .utf8) {
            let path: String
            if let file = file {
                path = file.pathLower!
            } else {
                path = directory! + "/" + nameTextField.text!
            }
            
            DropboxCache.instance.save(path: path, content: data) {
                self.activityIndicatorView.stopAnimating()
                self.reloadFile?()
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            saveButton.isEnabled = saveButtonIsEnabled()
            activityIndicatorView.stopAnimating()
        }
    }
    
    @IBAction func onTapGesture(_ sender: UITapGestureRecognizer) {
        if (dataTextView.isFirstResponder) {
            dataTextView.resignFirstResponder()
        }
    }
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Keyboard Observer
    @objc func keyboardWillShow(notification: Notification) {
        if (!dataTextView.isFirstResponder) {
            return
        }
        if let rect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double){
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: rect.size.height, right: 0)
            UIView.animate(withDuration: duration, animations: {
                self.scrollView.contentInset = contentInsets
                self.scrollView.scrollIndicatorInsets = contentInsets
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyborardWillHide(notification: Notification) {
        if (!dataTextView.isFirstResponder) {
            return
        }
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    private func registerKeyboardObserver() {
        let notification = NotificationCenter.default
        notification.addObserver(self, selector: #selector(FileEditViewController.keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        notification.addObserver(self, selector: #selector(FileEditViewController.keyborardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    private func removeObserver() {
        let notification = NotificationCenter.default
        notification.removeObserver(self)
    }
    
    private func saveButtonIsEnabled() -> Bool {
        return nameTextField.text != nil && nameTextField.text!.count > 0
    }
}

extension FileEditViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        navigationItem.title = nameTextField.text
        saveButton.isEnabled = saveButtonIsEnabled()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameTextField.resignFirstResponder()
        return true
    }
}
