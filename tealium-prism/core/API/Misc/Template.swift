//
//  Template.swift
//  tealium-prism
//
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A template that has already been compiled from a string containing double brace wrapped
 * substitutions: `{{ }}`.
 *
 * Compiling a template up-front (see `TemplateProcessor.compile(_:)`) parses the source once into
 * a list of plain-text and substitution sections. `process(context:)` then only has to join those
 * sections, substituting values for one or more contexts without re-scanning the source.
 *
 * The substitution paths the template references are collected during compilation and exposed via
 * `substitutions`, so callers can gather only the data the template actually needs.
 */
public struct Template {
    private let sections: [TemplateSection]

    /**
     * The paths of all the substitutions found while compiling this template, in the order they
     * appear. Substitutions whose path could not be parsed are not included.
     *
     * This is useful to know up-front which values a context needs to provide, so that
     * (potentially slow) work to populate the context can be limited to only the required data.
     */
    public let substitutions: [JSONObjectPath]

    init(sections: [TemplateSection]) {
        self.sections = sections
        self.substitutions = sections.compactMap { section in
            guard case let .substitution(path, _) = section else { return nil }
            return path
        }
    }

    /**
     * Processes this compiled template against the given `context`, replacing every substitution
     * with either the value extracted from the context, the substitution's fallback, or a blank
     * string `""` when neither is available.
     *
     * - Parameter context: the `DataObject` to extract substitution values from.
     * - Returns: A new string with all substitutions replaced.
     */
    public func process(context: DataObject) -> String {
        sections.map { $0.process(context: context) }.joined()
    }
}

/// One piece of a compiled `Template`: either a span of literal text or a substitution to be
/// resolved against a context at process time.
enum TemplateSection {
    case text(String)
    case substitution(path: JSONObjectPath, fallback: String?)

    func process(context: DataObject) -> String {
        switch self {
        case let .text(text):
            return text
        case let .substitution(path, fallback):
            if let item = context.extractDataItem(path: path),
               let formatted = DataItemFormatter.format(dataItem: item) {
                return formatted
            }
            return fallback ?? ""
        }
    }
}
