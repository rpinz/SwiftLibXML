//
//  XMLDocument.swift
//  Gtk3Swift
//
//  Created by Rene Hexel on 24/03/2016.
//  Copyright © 2016, 2018 Rene Hexel. All rights reserved.
//
#if os(Linux)
    import Glibc
    import CLibXML2
#else
    import Darwin
    import libxml2
#endif

///
/// A wrapper around libxml2 xmlDoc
///
public class XMLDocument {
    let xml: xmlDocPtr
    let ctx: xmlParserCtxtPtr? = nil

    /// private constructor from a libxml document
    init(xmlDocument: xmlDocPtr) {
        xml = xmlDocument
        xmlInitParser()
    }

    /// failable initialiser from memory with a given parser function
    public convenience init?(buffer: UnsafeBufferPointer<CChar>, options: Int32 = Int32(XML_PARSE_NOWARNING.rawValue | XML_PARSE_NOERROR.rawValue | XML_PARSE_RECOVER.rawValue), parser: ((UnsafePointer<CChar>?, Int32, UnsafePointer<CChar>?, UnsafePointer<CChar>?, Int32) -> xmlDocPtr?)? = nil) {
        guard let base = buffer.baseAddress else { return nil }
        let maybeXML: xmlDocPtr?
        if let parse = parser { maybeXML = parse(base, Int32(buffer.count), "", nil, options) }
        else { maybeXML = xmlReadMemory(base, Int32(buffer.count), "", nil, options) }
        guard let xml = maybeXML else { return nil }
        self.init(xmlDocument: xml)
    }

    /// initialise from a file
    public convenience init?(fromFile fileName: UnsafePointer<CChar>, options: Int32 = Int32(XML_PARSE_NOWARNING.rawValue | XML_PARSE_NOERROR.rawValue | XML_PARSE_RECOVER.rawValue)) {
        guard let xml = xmlParseFile(fileName) else { return nil }
        self.init(xmlDocument: xml)
    }

    /// clean up
    deinit {
        xmlFreeDoc(xml)
    }

    /// get the root element
    public var rootElement: XMLElement {
        return XMLElement(node: xmlDocGetRootElement(xml))
    }

    /// get the XML tree for enumeration
    public var tree: XMLTree {
        return XMLTree(xml: self)
    }

    /// get an attribute value
    public func valueFor(attribute: XMLAttribute) -> String? {
        let attr = attribute.attr
        guard let children = attr.pointee.children,
              let s = xmlNodeListGetString(xml, children, 1) else { return nil }
#if compiler(>=5.0)
        let value = String(cString: UnsafePointer<CChar>(s))
#else
        let value = String(cString: UnsafePointer(s))
#endif
        xmlFree(s)
        return value
    }

    /// get the value for a named attribute
    public func valueFor(attribute name: String, inElement e: XMLElement) -> String? {
        let attr = e.attributes.filter({$0.name == name}).first
        return attr.flatMap { valueFor(attribute: $0) }
    }
}


//
// MARK: - Enumerating XML
//
extension XMLDocument: Sequence {
    public typealias Iterator = XMLElement.Iterator
    public func makeIterator() -> Iterator {
        return Iterator(root: rootElement)
    }
}


///
/// Tree enumeration
///
public struct XMLTree: Sequence {
    public typealias Node = (level: Int, node: XMLElement, parent: XMLElement?)
    let document: XMLDocument

    public init(xml: XMLDocument) {
        document = xml
    }

    public class Iterator: IteratorProtocol {
        let level: Int
        let parent: XMLElement?
        var element: XMLElement?
        var child: Iterator?

        /// create a generator from a root element
        init(root: XMLElement, parent: XMLElement? = nil, level: Int = 0) {
            self.level = level
            self.parent = parent
            element = root
        }

        /// return the next element following a depth-first pre-order traversal
        public func next() -> Node? {
            if let c = child {
                if let element = c.next() { return element }         // children
                let sibling = element?.node.pointee.next
                element = sibling.map { XMLElement(node: $0 ) }
            }
            let children = element?.node.pointee.children
            child = children.map { Iterator(root: XMLElement(node: $0), parent: element, level: level+1) }
            return element.map { (level, $0, parent) }
        }
    }

    public func makeIterator() -> Iterator {
        return Iterator(root: document.rootElement)
    }
}
