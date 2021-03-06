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
    
    private func directoryFor(path: String) -> String {
        let pathComponents = path.split(separator: "/")
        let directory = "/" + pathComponents[0..<(pathComponents.count-1)].map { s in String(s) }.joined(separator: "/")
        return directory
    }
    
    func save(path: String, content: Data, _ handler: @escaping () -> Void) {
        client().map { client in
            client.files.upload(path: path, mode: Files.WriteMode.overwrite, autorename: false, clientModified: nil, mute: true, propertyGroups: nil, input: content).response { result, error in
                let directory = self.directoryFor(path: path)
                result.map { result in
                    self.expireCache(directory)
                    handler()
                }
                error.map { error in
                    fatalError("upload failed. \(error.description)")
                }
            }
        }
    }
    
    func delete(path: String, _ handler: @escaping () -> Void) {
        client().map { client in
            client.files.deleteV2(path: path).response { result, error in
                result.map { result in
                    self.expireCache(self.directoryFor(path: path))
                    handler()
                }
                error.map { fatalError("deleteV2 failed. \($0.description)") }
            }
        }
    }
    
    func handleAuthError<R>(_ error: Auth.AuthError) -> Either<String, R> {
        switch error {
        case .invalidAccessToken:
            return Either.Left("Invalid Access Token")
        case .userSuspended:
            return Either.Left("Suspended User")
        case .invalidSelectAdmin:
            return Either.Left("Invalid Select Admin")
        case .invalidSelectUser:
            return Either.Left("Invaid Select User")
        case .other:
            return Either.Left("Unknown Error. \(error.description)")
        }
    }
    
    func handleAccessError<R>(_ error: Auth.AccessError) -> Either<String, R> {
        switch error {
        case .other:
            return Either.Left("Unknown Error. \(error.description)")
        case .paperAccessDenied(let paperAccessError):
            switch paperAccessError {
            case .notPaperUser:
                return Either.Left("The provided user has not used Paper yet.")
            case .paperDisabled:
                return Either.Left("Paper is disabled.")
            case .other:
                return Either.Left("Unknown Error. \(paperAccessError.description)")
            }
        case .invalidAccountType(let invalidAccountTypeError):
            switch invalidAccountTypeError {
            case .endpoint:
                return Either.Left("Current account type doesn’t have permission to access this route endpoint.")
            case .feature:
                return Either.Left("Current account type doesn’t have permission to access this feature.")
            case .other:
                return Either.Left("Unkown Error. \(invalidAccountTypeError.description)")
                
            }
        }
    }
    
    func handleRateLimitError<R>(_ error: Auth.RateLimitError) -> Either<String, R> {
        return Either.Left("Rate Limitted. \(error.reason) Retry after: \(error.retryAfter)")
    }
    
    func download(path: String, _ handler: @escaping (Either<String, Data>) -> Void) {
        client().map { client in
            client.files.download(path: path).response { result, error in
                result.map { result in
                    let data = result.1
                    handler(Either.Right(data))
                }
                error.map {
                     switch $0 {
                     case .internalServerError(let code, let message, _):
                            handler(Either.Left("Internal Server Error. Code: \(code) \(message ?? "")"))
                     case .httpError(let code, let message, _):
                        handler(Either.Left("Http Error. Code: \(code ?? 0), \(message ?? "")"))
                     case .clientError(let clientError):
                        clientError.map { e in
                            handler(Either.Left("\(e.localizedDescription)"))
                        }
                     case .badInputError(let message, _):
                        handler(Either.Left("Bad Input: \(message ?? "")"))
                     case .authError(let authError, _, _, _):
                        handler(self.handleAuthError(authError))
                     case .accessError(let accessError, _, _, _):
                        handler(self.handleAccessError(accessError))
                     case .rateLimitError(let error, _, _, _):
                        handler(self.handleRateLimitError(error))
                     case let .routeError(box, _, _, _):
                        switch box.unboxed as Files.DownloadError {
                        case .other:
                            handler(Either.Left("Unknown Error."))
                        case .path(let lookupError):
                            switch lookupError {
                            case .malformedPath(let path):
                                handler(Either.Left("malformed path. \(path ?? "")"))
                            case .notFile:
                                handler(Either.Left("Not a File."))
                            case .notFolder:
                                handler(Either.Left("Not a Folder."))
                            case .notFound:
                                self.expireCache(self.directoryFor(path: path))
                                handler(Either.Left("\(path) not Found."))
                            case .restrictedContent:
                                handler(Either.Left("\(path) is restricted. can not download."))
                            case .other:
                                handler(Either.Left("Unknown Error."))
                            }
                        }
                     }
                }
            }
        }
    }
}
