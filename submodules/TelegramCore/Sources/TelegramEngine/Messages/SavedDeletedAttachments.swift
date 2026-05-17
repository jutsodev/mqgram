// MARK: MQGram - Saved Deleted Attachments (ported from GLEGram/SavedDeletedAttachments)
import Foundation
import Postbox

func mqSavedDeletedAttachmentsDirectoryPath(mediaBox: MediaBox) -> String {
    let path = mediaBox.basePath + "/saved-deleted-attachments"
    let _ = try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    return path
}

private func mqSanitizeFileName(_ value: String) -> String {
    var result = value
    for ch in ["/", ":", "\\", "\n", "\r", "\t"] {
        result = result.replacingOccurrences(of: ch, with: "_")
    }
    return result
}

private func mqCopyCompletedResourceIfPossible(mediaBox: MediaBox, resource: TelegramMediaResource, destinationDirectory: String) -> TelegramMediaResource? {
    guard let sourcePath = mediaBox.completedResourcePath(resource) else {
        return nil
    }
    let ext = URL(fileURLWithPath: sourcePath).pathExtension
    let baseName = mqSanitizeFileName(resource.id.stringRepresentation)
    let fileName = ext.isEmpty ? baseName : "\(baseName).\(ext)"
    let destinationPath = destinationDirectory + "/" + fileName

    if FileManager.default.fileExists(atPath: destinationPath) {
        return LocalFileReferenceMediaResource(localFilePath: destinationPath, randomId: Int64.random(in: Int64.min ... Int64.max), isUniquelyReferencedTemporaryFile: false, size: fileSize(destinationPath))
    }

    do {
        try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath)
        return LocalFileReferenceMediaResource(localFilePath: destinationPath, randomId: Int64.random(in: Int64.min ... Int64.max), isUniquelyReferencedTemporaryFile: false, size: fileSize(destinationPath))
    } catch {
        return nil
    }
}

private func mqCopyTelegramMediaImageForSavedDeleted(_ image: TelegramMediaImage, mediaBox: MediaBox, destinationDirectory: String) -> TelegramMediaImage {
    var updatedRepresentations: [TelegramMediaImageRepresentation] = []
    updatedRepresentations.reserveCapacity(image.representations.count)
    for rep in image.representations {
        if let localResource = mqCopyCompletedResourceIfPossible(mediaBox: mediaBox, resource: rep.resource, destinationDirectory: destinationDirectory) {
            updatedRepresentations.append(TelegramMediaImageRepresentation(
                dimensions: rep.dimensions,
                resource: localResource,
                progressiveSizes: rep.progressiveSizes,
                immediateThumbnailData: rep.immediateThumbnailData,
                hasVideo: rep.hasVideo,
                isPersonal: rep.isPersonal,
                typeHint: rep.typeHint
            ))
        } else {
            updatedRepresentations.append(rep)
        }
    }

    var updatedVideoRepresentations: [TelegramMediaImage.VideoRepresentation] = []
    updatedVideoRepresentations.reserveCapacity(image.videoRepresentations.count)
    for rep in image.videoRepresentations {
        if let localResource = mqCopyCompletedResourceIfPossible(mediaBox: mediaBox, resource: rep.resource, destinationDirectory: destinationDirectory) {
            updatedVideoRepresentations.append(TelegramMediaImage.VideoRepresentation(dimensions: rep.dimensions, resource: localResource, startTimestamp: rep.startTimestamp))
        } else {
            updatedVideoRepresentations.append(rep)
        }
    }

    return TelegramMediaImage(
        imageId: image.imageId,
        representations: updatedRepresentations,
        videoRepresentations: updatedVideoRepresentations,
        immediateThumbnailData: image.immediateThumbnailData,
        emojiMarkup: image.emojiMarkup,
        reference: image.reference,
        partialReference: image.partialReference,
        flags: image.flags
    )
}

private func mqCopyTelegramMediaFileForSavedDeleted(_ file: TelegramMediaFile, mediaBox: MediaBox, destinationDirectory: String) -> TelegramMediaFile {
    let updatedResource: TelegramMediaResource = mqCopyCompletedResourceIfPossible(mediaBox: mediaBox, resource: file.resource, destinationDirectory: destinationDirectory) ?? file.resource

    var updatedPreviewRepresentations: [TelegramMediaImageRepresentation] = []
    updatedPreviewRepresentations.reserveCapacity(file.previewRepresentations.count)
    for rep in file.previewRepresentations {
        if let localResource = mqCopyCompletedResourceIfPossible(mediaBox: mediaBox, resource: rep.resource, destinationDirectory: destinationDirectory) {
            updatedPreviewRepresentations.append(TelegramMediaImageRepresentation(
                dimensions: rep.dimensions,
                resource: localResource,
                progressiveSizes: rep.progressiveSizes,
                immediateThumbnailData: rep.immediateThumbnailData,
                hasVideo: rep.hasVideo,
                isPersonal: rep.isPersonal,
                typeHint: rep.typeHint
            ))
        } else {
            updatedPreviewRepresentations.append(rep)
        }
    }

    var updatedVideoThumbnails: [TelegramMediaFile.VideoThumbnail] = []
    updatedVideoThumbnails.reserveCapacity(file.videoThumbnails.count)
    for thumb in file.videoThumbnails {
        if let localResource = mqCopyCompletedResourceIfPossible(mediaBox: mediaBox, resource: thumb.resource, destinationDirectory: destinationDirectory) {
            updatedVideoThumbnails.append(TelegramMediaFile.VideoThumbnail(dimensions: thumb.dimensions, resource: localResource))
        } else {
            updatedVideoThumbnails.append(thumb)
        }
    }

    let updatedVideoCover = file.videoCover.flatMap { mqCopyTelegramMediaImageForSavedDeleted($0, mediaBox: mediaBox, destinationDirectory: destinationDirectory) }

    return TelegramMediaFile(
        fileId: file.fileId,
        partialReference: file.partialReference,
        resource: updatedResource,
        previewRepresentations: updatedPreviewRepresentations,
        videoThumbnails: updatedVideoThumbnails,
        videoCover: updatedVideoCover,
        immediateThumbnailData: file.immediateThumbnailData,
        mimeType: file.mimeType,
        size: file.size,
        attributes: file.attributes,
        alternativeRepresentations: file.alternativeRepresentations
    )
}

public func mqTransformMediaForSavedDeletedSnapshot(message: Message, mediaBox: MediaBox) -> [Media] {
    let destinationDirectory = mqSavedDeletedAttachmentsDirectoryPath(mediaBox: mediaBox)

    return message.media.map { media in
        if let image = media as? TelegramMediaImage {
            return mqCopyTelegramMediaImageForSavedDeleted(image, mediaBox: mediaBox, destinationDirectory: destinationDirectory)
        } else if let file = media as? TelegramMediaFile {
            return mqCopyTelegramMediaFileForSavedDeleted(file, mediaBox: mediaBox, destinationDirectory: destinationDirectory)
        } else {
            return media
        }
    }
}

private func mqCollectLocalPaths(from resource: TelegramMediaResource, into result: inout [String]) {
    if let resource = resource as? LocalFileReferenceMediaResource {
        result.append(resource.localFilePath)
    }
}

private func mqCollectLocalPaths(from media: Media, into result: inout [String]) {
    if let image = media as? TelegramMediaImage {
        for rep in image.representations {
            mqCollectLocalPaths(from: rep.resource, into: &result)
        }
        for rep in image.videoRepresentations {
            mqCollectLocalPaths(from: rep.resource, into: &result)
        }
    } else if let file = media as? TelegramMediaFile {
        mqCollectLocalPaths(from: file.resource, into: &result)
        for rep in file.previewRepresentations {
            mqCollectLocalPaths(from: rep.resource, into: &result)
        }
        for thumb in file.videoThumbnails {
            mqCollectLocalPaths(from: thumb.resource, into: &result)
        }
        if let cover = file.videoCover {
            mqCollectLocalPaths(from: cover, into: &result)
        }
    }
}

public func mqDeleteSavedDeletedAttachmentsForMessage(_ message: Message) {
    var paths: [String] = []
    for media in message.media {
        mqCollectLocalPaths(from: media, into: &paths)
    }
    guard !paths.isEmpty else { return }

    for path in Set(paths) {
        let _ = try? FileManager.default.removeItem(atPath: path)
    }
}
