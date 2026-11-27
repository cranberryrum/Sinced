//
//  CardStyle.swift
//  Shared (app + widget)
//
//  How a counter's card lays out its count, on Sinced's home and in the
//  widgets' Style option. Independent of the theme: every theme works in
//  every style.
//

import Foundation

enum CardStyle: String, Codable, CaseIterable, Identifiable {
    case classic, bigNumber, sentence, ring

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: return "Classic"
        case .bigNumber: return "Big number"
        case .sentence: return "Sentence"
        case .ring: return "Milestone ring"
        }
    }
}
