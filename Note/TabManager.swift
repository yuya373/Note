//
//  TabManager.swift
//  Note
//
//  Created by 南優也 on 2018/03/11.
//  Copyright © 2018年 南優也. All rights reserved.
//

import UIKit
import CoreData

class TabManager {
    static func bookmarkTab() -> Tab? {
        let request: NSFetchRequest<Tab> = Tab.fetchRequest()
        do {
            let tabs = try context().fetch(request)
            if (tabs.count > 0) {
                return tabs[0]
            } else {
                return nil
            }
        } catch {
            fatalError("failed to fetch tabs")
        }
    }
    
    static func updateBookmark(path: String) {
        if let tab = bookmarkTab() {
            tab.path = path
        } else {
            let tab = Tab(context: context())
            tab.path = path
        }
        save()
    }
    
    private static func context() -> NSManagedObjectContext {
        return delegate().persistentContainer.viewContext
    }
    
    private static func delegate() -> AppDelegate {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("failed to fetch AppDelegate")
        }
        return appDelegate
    }
    
    private static func save() {
        delegate().saveContext()
    }
}
