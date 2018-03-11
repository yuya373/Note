//
//  Dropbox.swift
//  Note
//
//  Created by 南優也 on 2018/03/10.
//  Copyright © 2018年 南優也. All rights reserved.
//
import SwiftyDropbox
import CoreData

final class DropboxCache {
    static let instance = DropboxCache()
    
    
    static let isFolder: (Metadata) -> Bool = { file in
        file is Folder
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

    private var cachedFiles: [String: [File]] = [:]
    private var cachedFolders: [String: [Folder]] = [:]
    private init() {
        let context = DropboxCache.delegate().persistentContainer.viewContext
        do {
            let request: NSFetchRequest<File> = File.fetchRequest()
            let files = try context.fetch(request)
            files.forEach { file in
                let directory = file.directory ?? ""
                self.cachedFiles[directory] == nil ?
                    self.cachedFiles[directory] = [file] :
                    self.cachedFiles[directory]?.append(file)
            }
        } catch {
            fatalError("Failed to load File")
        }
        do {
            let request: NSFetchRequest<Folder> = Folder.fetchRequest()
            let folders = try context.fetch(request)
            folders.forEach { folder in
                let directory = folder.directory ?? ""
                self.cachedFolders[directory] == nil ?
                    self.cachedFolders[directory] = [folder] :
                    self.cachedFolders[directory]?.append(folder)
            }
        } catch {
            fatalError("Failed to load Folder")
        }
    }
    
    private func client() -> DropboxClient? {
        return DropboxClientsManager.authorizedClient
    }
    
    private static func delegate() -> AppDelegate {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("failed to fetch Delegate")
        }
        return delegate
    }
    
    func initFile(source: Files.FileMetadata, directory: String) -> File {
        let context = DropboxCache.delegate().persistentContainer.viewContext
        let file = File(context: context)
        file.name = source.name
        file.pathLower = source.pathLower
        file.pathDisplay = source.pathDisplay
        file.description_ = source.description
        file.id = source.id
        file.contentHash = source.contentHash
        file.serverModified = source.serverModified
        file.rev = source.rev
        file.directory = directory

        return file
    }
    
    func initFolder(source: Files.FolderMetadata, directory: String) -> Folder {
        let context = DropboxCache.delegate().persistentContainer.viewContext
        let folder = Folder(context: context)
        folder.id = source.id
        folder.name = source.name
        folder.pathLower = source.pathLower
        folder.pathDisplay = source.pathDisplay
        folder.description_ = source.description
        folder.directory = directory
        return folder
    }
    
    private func buildCachedFiles(entries: [Files.Metadata], directory: String) -> [File] {
        return entries.filter { !(DropboxCache.hasMedia($0)) && $0 is Files.FileMetadata }.map {
            return self.initFile(source: $0 as! Files.FileMetadata, directory: directory)
        }
    }
    
    private func buildCachedFolders(entries: [Files.Metadata], directory: String) -> [Folder] {
        return entries.filter { !(DropboxCache.hasMedia($0)) && $0 is Files.FolderMetadata }.map {
            return self.initFolder(source: $0 as! Files.FolderMetadata, directory: directory)
        }
    }
    
    private func expireCache(_ path: String) {
        let context = DropboxCache.delegate().persistentContainer.viewContext
        cachedFiles[path]?.forEach { file in
            context.delete(file)
        }
        cachedFiles[path] = nil
        cachedFolders[path]?.forEach { folder in
            context.delete(folder)
        }
        cachedFolders[path] = nil
    }
    
    func files(path: String, refresh: Bool = false, _ handler: @escaping ([File], [Folder]) -> Void) {
        if (!refresh && ((cachedFiles[path]?.count ?? 0) > 0 || (cachedFolders[path]?.count ?? 0) > 0)) {
            let files = cachedFiles[path] ?? []
            let folders = cachedFolders[path] ?? []
            print("cached files: \(files.count)")
            print("cached folders: \(folders.count)")
            handler(files, folders)
        } else {
            expireCache(path)
            client().map { client in
                client.files.listFolder(path: path, recursive: false, includeMediaInfo: true, includeDeleted: false, includeHasExplicitSharedMembers: false, includeMountedFolders: false, limit: nil, sharedLink: nil, includePropertyGroups: nil).response { result, error in
                    result.map { result in
                        self.cachedFiles[path] = self.buildCachedFiles(entries: result.entries, directory: path)
                        self.cachedFolders[path] = self.buildCachedFolders(entries: result.entries, directory: path)

                        if (result.hasMore) {
                            self.filesContinue(path: path, result.cursor, handler)
                        } else {
                            DropboxCache.delegate().saveContext()
                            handler(self.cachedFiles[path] ?? [], self.cachedFolders[path] ?? [])
                        }
                    }
                    error.map { error in
                        fatalError("listFolder failed. \(error.description)")
                    }
                }
            }
        }
    }
    
    private func filesContinue(path: String, _ cursor: String, _ handler: @escaping ([File], [Folder]) -> Void) {
        client().map { client in
            client.files.listFolderContinue(cursor: cursor).response { result, error in
                result.map { result in
                    self.cachedFiles[path] = (self.cachedFiles[path] ?? []) + self.buildCachedFiles(entries: result.entries, directory: path)
                    self.cachedFolders[path] = (self.cachedFolders[path] ?? []) + self.buildCachedFolders(entries: result.entries, directory: path)
                    
                    if (result.hasMore) {
                        self.filesContinue(path: path, result.cursor, handler)
                    } else {
                        DropboxCache.delegate().saveContext()
                        handler(self.cachedFiles[path] ?? [], self.cachedFolders[path] ?? [])
                    }
                }
                error.map { error in
                    fatalError("listFolderContinue failed. \(error.description)")
                }
            }
        }
    }
}
