//
//  UITabBarViewController.swift
//  Note
//
//  Created by 南優也 on 2018/03/11.
//  Copyright © 2018年 南優也. All rights reserved.
//

import UIKit
import CoreData

class UITabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        TabManager.bookmarkTab().map { tab in
            tab.path.map { addBookmark(path: $0, select: true) }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addBookmark(path: String, select: Bool = false) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "ListViewController") as? ListViewController {
            vc.path = path
            vc.opType = .bookmark
            
            let tab2 = UINavigationController(rootViewController: vc)
            let title = path == "" ? "/" : path
            
            var viewControllers = self.viewControllers?.filter { vc in
                if let listViewController = vc.childViewControllers[0] as? ListViewController {
                    return listViewController.opType == .browse
                } else {
                    return true
                }
                } ?? []
            
            tab2.tabBarItem = UITabBarItem(title: title, image: nil, tag: viewControllers.count)
            viewControllers.append(tab2)
            setViewControllers(viewControllers, animated: false)
            
            if (select) {
                selectedIndex = max(viewControllers.count - 1, 0)
            }
        }
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
