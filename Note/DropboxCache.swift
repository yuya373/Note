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
    
    
    static let isFolder: (Files.Metadata) -> Bool = { file in
        file is Files.FolderMetadata
    }
    static let isMarkDown: (Files.Metadata) -> Bool = { file in
        file.name.hasSuffix(".md")
    }
    static let isOrg: (Files.Metadata) -> Bool = { file in
        file.name.hasSuffix(".org")
    }
    static let folderOrMarkDownOrOrg: (Files.Metadata) -> Bool = { file in
        isFolder(file) || isMarkDown(file) || isOrg(file)
    }
    
    private var cachedFiles = [Files.Metadata]()
    private init() {}
    
    private func client() -> DropboxClient? {
        return DropboxClientsManager.authorizedClient
    }
    
    func files(path: String, refresh: Bool = false, _ handler: @escaping ([Files.Metadata]) -> Void) {
        if (!refresh && cachedFiles.count > 0) {
            handler(cachedFiles)
        } else {
            // client().map { client in
                DropboxClientsManager.authorizedClient!.files.listFolder(path: path, recursive: false, includeMediaInfo: true, includeDeleted: false, includeHasExplicitSharedMembers: false, includeMountedFolders: false, limit: 50, sharedLink: nil, includePropertyGroups: nil).response { result, error in
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
            // }
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
