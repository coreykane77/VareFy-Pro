import UIKit
import Supabase

enum PhotoService {

    enum PhotoError: LocalizedError {
        case compressionFailed

        var errorDescription: String? {
            switch self {
            case .compressionFailed: return "Failed to compress photo."
            }
        }
    }

    // Upload a photo to Supabase Storage and insert a work_order_photos row.
    // Returns a confirmed PhotoRecord with the real storage path.
    static func uploadPhoto(
        _ image: UIImage,
        photoType: String,
        workOrderId: UUID,
        uploadedBy: UUID
    ) async throws -> PhotoRecord {
        let photoId = UUID()
        let path = "\(workOrderId.uuidString.lowercased())/\(photoType)/\(photoId.uuidString.lowercased()).jpg"

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw PhotoError.compressionFailed
        }

        try await supabase.storage
            .from("work-orders")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))

        struct PhotoInsert: Encodable {
            let id: UUID
            let work_order_id: UUID
            let uploaded_by: UUID
            let photo_type: String
            let storage_path: String
        }

        try await supabase
            .from("work_order_photos")
            .insert(PhotoInsert(
                id: photoId,
                work_order_id: workOrderId,
                uploaded_by: uploadedBy,
                photo_type: photoType,
                storage_path: path
            ))
            .execute()

        return PhotoRecord(id: photoId, storagePath: path, localImage: image, isUploading: false)
    }

    // Delete a photo from Supabase Storage and remove the work_order_photos row.
    static func deletePhoto(record: PhotoRecord) async throws {
        guard !record.storagePath.isEmpty else { return }
        try await supabase.storage
            .from("work-orders")
            .remove(paths: [record.storagePath])
        try await supabase
            .from("work_order_photos")
            .delete()
            .eq("id", value: record.id)
            .execute()
    }

    // Fetch existing photo records for a work order, generating signed URLs for display.
    static func fetchPhotos(workOrderId: UUID, photoType: String) async throws -> [PhotoRecord] {
        struct PhotoRow: Decodable {
            let id: UUID
            let storage_path: String
        }

        let rows: [PhotoRow] = try await supabase
            .from("work_order_photos")
            .select("id, storage_path")
            .eq("work_order_id", value: workOrderId)
            .eq("photo_type", value: photoType)
            .order("uploaded_at")
            .execute()
            .value

        return try await withThrowingTaskGroup(of: PhotoRecord.self) { group in
            for row in rows {
                group.addTask {
                    let url = try await supabase.storage
                        .from("work-orders")
                        .createSignedURL(path: row.storage_path, expiresIn: 3600)
                    return PhotoRecord(id: row.id, storagePath: row.storage_path, signedURL: url, isUploading: false)
                }
            }
            var records: [PhotoRecord] = []
            for try await record in group {
                records.append(record)
            }
            // Restore insertion order (task group doesn't guarantee it)
            return records.sorted { a, b in
                let ai = rows.firstIndex { $0.id == a.id } ?? 0
                let bi = rows.firstIndex { $0.id == b.id } ?? 0
                return ai < bi
            }
        }
    }
}
