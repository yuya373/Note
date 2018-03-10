//
//  Dropbox.swift
//  Note
//
//  Created by 南優也 on 2018/03/10.
//  Copyright © 2018年 南優也. All rights reserved.
//
import SwiftyDropbox

final class DropboxCache {
    static let instance = DropboxCache()
    
    private var cachedFiles = [Files.Metadata]()
    private init() {}
    
    private func client() -> DropboxClient? {
        return DropboxClientsManager.authorizedClient
    }
    
    func files(refresh: Bool = false, _ handler: @escaping ([Files.Metadata]) -> Void) {
        if (!refresh && cachedFiles.count > 0) {
            handler(cachedFiles)
        } else {
            client().map { client in
                client.files.listFolder(path: "", recursive: false, includeMediaInfo: true, includeDeleted: false, includeHasExplicitSharedMembers: false, includeMountedFolders: false, limit: 50, sharedLink: nil, includePropertyGroups: nil).response { result, error in
                    result.map { result in
                        self.cachedFiles = result.entries
                        
                        if (result.hasMore) {
                            self.filesContinue(result.cursor, handler)
                        } else {
                            handler(self.cachedFiles)
                        }
                    }
                    error.map { error in
                        fatalError("listFolder failed. \(error.description)")
                    }
                }
            }
        }
    }
    
    private func filesContinue(_ cursor: String, _ handler: @escaping ([Files.Metadata]) -> Void) {
        client().map { client in
            client.files.listFolderContinue(cursor: cursor).response { result, error in
                result.map { result in
                    self.cachedFiles += result.entries
                    if (result.hasMore) {
                        self.filesContinue(result.cursor, handler)
                    } else {
                        handler(self.cachedFiles)
                    }
                }
                error.map { error in
                    fatalError("listFolderContinue failed. \(error.description)")
                }
            }
        }
    }
}
