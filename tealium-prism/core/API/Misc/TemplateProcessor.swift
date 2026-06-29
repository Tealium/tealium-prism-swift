//
//  TemplateProcessor.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 27/11/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// Utility to replace double brace wrapped text with values extracted from a `DataObject`.
public class TemplateProcessor {
    private static let handlebarsRegex = try? NSRegularExpression(pattern: "\\{\\{\\s*(.*?)\\s*\\}\\}")

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
        compile(text).process(context: context)
    }

    /**
     * Compiles the input `text` into a reusable `Template`, scanning once to split the source into
     * plain-text and substitution sections. The substitution paths it references are collected
     * ahead of time (see `Template.substitutions`).
     *
     * This lets callers learn up-front which values a context needs to provide - so (potentially slow)
     * work to populate the context can be limited to only the required data - before processing the
     * template against one or more contexts via `Template.process(context:)`.
     *
     * Each substitution block follows the same rules as `process(text:context:)`.
     *
     * - Parameter text: the String to compile, looking for `{{ }}` substitution blocks.
     * - Returns: A compiled `Template`.
     */
    public class func compile(_ text: String) -> Template {
        guard let handlebarsRegex else {
            return Template(sections: [.text(text)])
        }

        let nsText = text as NSString
        var sections: [TemplateSection] = []
        var lastLocation = 0

        for match in handlebarsRegex.matches(in: text, range: NSRange(location: 0, length: nsText.length)) {

            if match.range.location > lastLocation {
                let precedingRange = NSRange(location: lastLocation,
                                             length: match.range.location - lastLocation)
                sections.append(.text(nsText.substring(with: precedingRange)))
            }

            let innerRange = match.range(at: 1)
            let inner = innerRange.location != NSNotFound ? nsText.substring(with: innerRange) : ""
            sections.append(section(from: inner))

            lastLocation = match.range.location + match.range.length
        }

        if lastLocation < nsText.length {
            sections.append(.text(nsText.substring(from: lastLocation)))
        }

        return Template(sections: sections)
    }

    /// Parses the content inside a `{{ }}` block into a section. The content is `path || fallback`,
    /// where only the first `||` separates path from fallback (extra `||` parts are ignored) and
    /// both are trimmed. An unparsable path (including a blank one) becomes literal text - the
    /// fallback if present, otherwise an empty string.
    private static func section(from inner: String) -> TemplateSection {
        let parts = inner.components(separatedBy: "||")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        let pathString = parts.first ?? ""
        let fallback = parts.count > 1 ? parts[1] : nil

        guard let path = try? JSONObjectPath.parse(pathString) else {
            return .text(fallback ?? "")
        }
        return .substitution(path: path, fallback: fallback)
    }
}
