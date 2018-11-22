//
//  XMLElement.swift
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
/// A wrapper around libxml2 xmlElement
///
public struct XMLElement {
    let node: xmlNodePtr
}

extension XMLElement {
    /// name of the XML element
    public var name: String {
        let name: UnsafePointer<xmlChar>? = node.pointee.name
        return name.map { String(cString: UnsafePointer($0)) } ?? ""
    }

    /// content of the XML element
    public var content: String {
        let content: UnsafeMutablePointer<xmlChar>? = xmlNodeGetContent(node)
#if swift(>=4.2)
#if compiler(>=5.0)
        let txt = content.map { String(cString: UnsafePointer<CChar>($0)) } ?? ""
#else
        let txt = content.map { String(cString: UnsafePointer($0)) } ?? ""
#endif
#else
        let txt = content.map { String(cString: UnsafePointer($0)) } ?? ""
#endif
        xmlFree(content)
        return txt
    }

    /// attributes of the XML element
    public var attributes: AnySequence<XMLAttribute> {
        guard node.pointee.properties != nil else { return emptySequence() }
        return AnySequence { XMLAttribute(attr: self.node.pointee.properties).makeIterator() }
    }

    /// parent of the XML element
    public var parent: XMLElement {
        return XMLElement(node: node.pointee.parent)
    }

    /// siblings of the XML element
    public var siblings: AnySequence<XMLElement> {
        guard node.pointee.next != nil else { return emptySequence() }
        return AnySequence { XMLElement(node: self.node.pointee.next).levelIterator() }
    }

    /// children of the XML element
    public var children: AnySequence<XMLElement> {
        guard node.pointee.children != nil else { return emptySequence() }
        return AnySequence { XMLElement(node: self.node.pointee.children).levelIterator() }
    }

    /// recursive pre-order descendants of the XML element
    public var descendants: AnySequence<XMLElement> {
        guard node.pointee.children != nil else { return emptySequence() }
        return AnySequence { XMLElement(node: self.node.pointee.children).makeIterator() }
    }

    /// return the value of a given attribute
    public func attribute(named n: String) -> String? {
        let value: UnsafeMutablePointer<xmlChar>? = xmlGetProp(node, n)
#if swift(>=4.2)
#if compiler(>=5.0)
        return value.map { String(cString: UnsafePointer<CChar>($0)) } ?? ""
#else
        return value.map { String(cString: UnsafePointer($0)) } ?? ""
#endif
#else
        return value.map { String(cString: UnsafePointer($0)) } ?? ""
#endif
    }

    /// return the value of a given attribute in a given name space
    public func attribute(named name: String, namespace: String) -> String? {
        let value: UnsafeMutablePointer<xmlChar>? = xmlGetNsProp(node, name, namespace)
#if swift(>=4.2)
#if compiler(>=5.0)
        return value.map { String(cString: UnsafePointer<CChar>($0)) } ?? ""
#else
        return value.map { String(cString: UnsafePointer($0)) } ?? ""
#endif
#else
        return value.map { String(cString: UnsafePointer($0)) } ?? ""
#endif
    }

    /// return the boolean value of a given attribute
    public func bool(named n: String) -> Bool {
        if let str = attribute(named: n),
           let val = Int(str), val != 0 {
            return true
        } else {
            return false
        }
    }

    /// return the boolean value of a given attribute in a given name space
    public func bool(named n: String, namespace: String) -> Bool {
        if let str = attribute(named: n, namespace:  namespace),
           let val = Int(str), val != 0 {
            return true
        } else {
            return false
        }
    }
}


//
// MARK: - Conversion to String
//
extension XMLElement: CustomStringConvertible {
    public var description: String { return name }
}

extension XMLElement: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(description): \(node.pointee.type)"
    }
}

//
// MARK: - Enumerating XML Elements
//
extension XMLElement: Sequence {
    /// return a recursive, depth-first, pre-order traversal generator
    public func makeIterator() -> XMLElement.Iterator {
        return Iterator(root: self)
    }

    /// return a one-level (breadth-only) generator
    public func levelIterator() -> XMLElement.LevelIterator {
        return LevelIterator(root: self)
    }
}


extension XMLElement {
    /// Iterator for depth-first, pre-order enumeration
    public class Iterator: IteratorProtocol {
        var element: XMLElement?
        var child: Iterator?

        /// create a generator from a root element
        init(root: XMLElement) {
            element = root
        }

        /// return the next element following a depth-first pre-order traversal
        public func next() -> XMLElement? {
            if let c = child {
                if let element = c.next() { return element }         // children
                let sibling = element?.node.pointee.next
                element = sibling.map { XMLElement(node: $0 ) }
            }
            let children = element?.node.pointee.children
            child = children.map { XMLElement(node: $0).makeIterator() }
            return element
        }
    }

    /// Flat generator for horizontally traversing one level of the tree
    public class LevelIterator: IteratorProtocol {
        var element: XMLElement?

        /// create a sibling generator from a root element
        init(root: XMLElement) {
            element = root
        }

        /// return the next element following the list of siblings
        public func next() -> XMLElement? {
            let e = element
            let sibling = e?.node.pointee.next
            element = sibling.map(XMLElement.init)
            return e
        }
    }
}


//
// MARK: - Namespaces
//
extension XMLElement {
    /// name spaces of the XML element
    public var namespaces: AnySequence<XMLNameSpace> {
        guard node.pointee.nsDef != nil else { return emptySequence() }
        return AnySequence { XMLNameSpace(ns: self.node.pointee.nsDef).makeIterator() }
    }
}
