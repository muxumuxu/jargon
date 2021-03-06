//
//  i18nWriter.swift
//  jargon
//
//  Created by David Miotti on 18/03/2017.
//
//

import Foundation
import Yams

/// Write translations files in the current directory
///
/// - Parameters:
/// - translations: Translations to write
/// - Throws: Error writing the translation
func writei18n(_ translations: [Translation]) throws -> [URL] {
    return try translations.map {
        try write(translation: $0)
    }
}

/// Write a translation on disk based on the project name
///
/// - Parameters:
/// - translation: The translation to be written
/// - Throws: Most of the time a filesystem permission problem or insufficient disk space
private func write(translation: Translation) throws -> URL {
    let fileUrl = try buildFilePath(for: translation)
    let contents = try fileContents(for: translation)
    let data = contents.data(using: .utf8)
    try data?.write(to: fileUrl)
    return fileUrl
}

/// Transform a Translation object to a string content
///
/// - Parameter translation: The translation to be transformed
/// - Returns: The string containing the translation text
private func fileContents(for translation: Translation) throws -> String {
    let converted = convertToYAMLDictionnary(translation)
	return try Yams.dump(object: converted)
}

/// Convert a Translation to a dictionnary formatted as YAML
///
/// - Parameter translation: The translation to be converted
/// - Returns: A dictionnary containing the translation on a YAML format
private func convertToYAMLDictionnary(_ translation: Translation) -> [String: Any] {
    let dict = NSMutableDictionary()
	for (tradKey, tradValue) in translation.translations {
        let allKeys = tradKey.components(separatedBy: ".")
        guard let keyName = allKeys.last else { continue }
        let spaces = allKeys.dropLast()
        var currentDict: NSMutableDictionary? = dict
        for space in spaces {
            if currentDict?[space] == nil {
                let nextDict = NSMutableDictionary()
                currentDict?[space] = nextDict
                currentDict = nextDict
            } else {
                currentDict = currentDict?[space] as? NSMutableDictionary
            }
        }
        if let currentDict = currentDict {
            currentDict[keyName] = tradValue
        }
    }
    
    return [ translation.lang: convertObjCDictionaryToSwiftDictionary(dictionary: dict) ]
}

private func convertObjCDictionaryToSwiftDictionary(dictionary: NSDictionary) -> [String: Any] {
    var newDict = [String: Any]()
    for (key, value) in dictionary {
        guard let key = key as? String else { continue }
        if let nested = value as? NSDictionary {
            newDict[key] = convertObjCDictionaryToSwiftDictionary(dictionary: nested)
        } else {
            newDict[key] = value
        }
    }
    return newDict
}

/// Transform a Translation object to a string content
///
/// - Parameter translation: The translation to be transformed
/// - Returns: The string containing the translation text
func buildFilePath(for translation: Translation) throws -> URL {
    let fileManager = FileManager.default
    let currDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    let localesDir = currDir.appendingPathComponent("config/locales", isDirectory: true)
    try fileManager.createDirectory(at: localesDir, withIntermediateDirectories: true, attributes: nil)
    return localesDir.appendingPathComponent("\(translation.lang).yml")
}
