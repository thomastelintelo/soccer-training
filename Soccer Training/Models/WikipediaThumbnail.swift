// WikipediaThumbnail.swift
// Minimal decoding shapes for the Wikipedia page-summary thumbnail, shared by
// ClubCrestView (team crests) and PlayerPhotoView (player photos).

import Foundation

struct WikipediaPlayerSummary: Decodable {
    let thumbnail: WikipediaPlayerThumbnail?
}

struct WikipediaPlayerThumbnail: Decodable {
    let source: URL
}
