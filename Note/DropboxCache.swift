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
        file.name.hasSuffix(".md") || file.name.hasSuffix(".markdown")
    }
    static let isOrg: (Files.Metadata) -> Bool = { file in
        file.name.hasSuffix(".org")
    }
    static let hasMedia: (Files.Metadata) -> Bool = { file in
        if let f = file as? Files.FileMetadata {
            return f.mediaInfo != nil
        } else {
            return false
        }
    }
    static let folderOrMarkDownOrOrg: (Files.Metadata) -> Bool = { file in
        isFolder(file) || isMarkDown(file) || isOrg(file)
    }
    
    private var cachedFiles: [String: [Files.Metadata]] = [:]
    private init() {}
    
    private func client() -> DropboxClient? {
        return DropboxClientsManager.authorizedClient
    }
    
    func files(path: String, refresh: Bool = false, _ handler: @escaping ([Files.Metadata]) -> Void) {
        if (!refresh && (cachedFiles[path]?.count ?? 0) > 0) {
            handler(cachedFiles[path] ?? [])
        } else {
            client().map { client in
                client.files.listFolder(path: path, recursive: false, includeMediaInfo: true, includeDeleted: false, includeHasExplicitSharedMembers: false, includeMountedFolders: false, limit: nil, sharedLink: nil, includePropertyGroups: nil).response { result, error in
                    result.map { result in
                        self.cachedFiles[path] = result.entries
                        
                        if (result.hasMore) {
                            self.filesContinue(path: path, result.cursor, handler)
                        } else {
                            handler(self.cachedFiles[path] ?? [])
                        }
                    }
                    error.map { error in
                        fatalError("listFolder failed. \(error.description)")
                    }
                }
            }
        }
    }
    
    private func filesContinue(path: String, _ cursor: String, _ handler: @escaping ([Files.Metadata]) -> Void) {
        client().map { client in
            client.files.listFolderContinue(cursor: cursor).response { result, error in
                result.map { result in
                    self.cachedFiles[path] = (self.cachedFiles[path] ?? []) + result.entries
                    if (result.hasMore) {
                        self.filesContinue(path: path, result.cursor, handler)
                    } else {
                        handler(self.cachedFiles[path] ?? [])
                    }
                }
                error.map { error in
                    fatalError("listFolderContinue failed. \(error.description)")
                }
            }
        }
    }
}
