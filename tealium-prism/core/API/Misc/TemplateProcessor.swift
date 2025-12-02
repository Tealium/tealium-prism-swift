//
//  TemplateProcessor.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 27/11/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// Utility to replace double brace wrapped text with values extracted from a `DataObject`.
public class TemplateProcessor {
    private static let handlebarsRegex = "\\{\\{(.*?)\\}\\}"

    /**
     * Processes the input `text` looking for all occurrences of double brace wrapped text: `{{  }}`
     *
     * The format of text inside the braces can be as follows:
     *  - a valid json path style string: e.g. `{{container.key}}`
     *  - a valid json path style string with an optional fallback: e.g. `{{container.key || fallback}}`
     *     - in the event that `container.key` is not available in the `context` object, the fallback will be used
     *
     * All occurrences of the templating `{{ }}` will be replaced with either the value from the `context`
     * object according to the json path specified, or the fallback string if provided, else a blank string `""`
     *
     * - Parameters:
     *   - text: the String to process for `{{ }}` substitution block
     *   - context: the `DataObject` to extract values from
     *
     * - Returns: A new string with all substitution blocks replaced
     */
    public class func process(text: String, context: DataObject) -> String {
        guard let groups = try? text.groups(for: handlebarsRegex) else {
            return text
        }
        return groups.reduce(text, { partialResult, matches in
            guard matches.count > 1 else {
                return partialResult
            }
            let result = processHandlebarsTemplate(matches[1], context: context)
            return partialResult.replacingOccurrences(of: matches[0], with: result ?? "")
        })
    }

    private static func processHandlebarsTemplate(_ template: String, context: DataObject) -> String? {
        var parts = template.components(separatedBy: "||")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .prefix(2) // [path, fallback]
        guard let path = parts.popFirst() else {
            return nil
        }
        return processJsonPath(path, context: context) ?? parts.first
    }

    private static func processJsonPath(_ path: String, context: DataObject) -> String? {
        guard let jsonPath = try? JSONObjectPath.parse(path),
            let item = context.extractDataItem(path: jsonPath) else {
            return nil
        }
        return DataItemFormatter.format(dataItem: item)
    }
}

fileprivate extension String {
    func groups(for regexPattern: String) throws -> [[String]] {
        let text = self
        let regex = try NSRegularExpression(pattern: regexPattern)
        let matches = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return matches.map { match in
            return (0..<match.numberOfRanges).map {
                let rangeBounds = match.range(at: $0)
                guard let range = Range(rangeBounds, in: text) else {
                    return ""
                }
                return String(text[range])
            }
        }
    }
}
