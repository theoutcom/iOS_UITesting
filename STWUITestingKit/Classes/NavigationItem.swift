//
//  Navigation.swift
//  JSONSTWSchema
//
//  Created by Tal Zion on 22/03/2017.
//  Copyright © 2017 Stanwood GmbH. All rights reserved.
//

import Foundation

typealias JSON = [AnyHashable: Any]

extension String {
    
    func validate() throws {
        let split = self.components(separatedBy: ".")
        
        /// Checcking STWSchema for action
        guard split.contains(UITesting.Key.action) else { throw UITesting.TestError.error("STWSchema navigation does not contain an action") }
        
        /// Checking for a valid action
        if let index = split.index(of: UITesting.Key.action), split.count >= (index + 1) {
            let key = split[index + 1]
            guard let _ = UITesting.Action(rawValue: key) else { throw UITesting.TestError.error("STWSchema navigation does not contain a valid action: \(key)") }
        }
    }
    
    func toInt() -> Int? {
        return Int(self)
    }
}

extension UITesting {
    
    struct Key {
        static let action = "action"
        static let type = "type"
        static let index = "index"
        static let key = "key"
        static let order = "order"
        static let successor = "successor"
        static let monitor = "monitor"
    }
    
    /*
     NavigationIten represents a navigation junction within a stack
     */
    open class NavigationItem {
        
        struct Constants {
            static let monitorIndex = 3
        }
        
        public var type: NavigationType!
        public var index: Int?
        public var key: String!
        public var successor: NavigationItem?
        public var action: Action?
        public var sequence: Int!
        public var shouldMonitor: Bool = false
        
        public init(format: String) throws {
            do {
                /// Validating STWSchema
                try format.validate()
                
                // Getting navigation components
                var components = format.components(separatedBy: ".")
                
                // Checking if the navigation should be monitored for system alerts
                try shouldMonitor(&components)
                
                // Converting components to item format
                try convert(format: components)
                
            } catch  {
                throw error
            }
        }
        
        private init(dictionary: [AnyHashable:Any]) throws {
            do {
                try setup(test: dictionary)
                
            } catch  {
                throw error
            }
        }
        
        private init(components:[String]) throws {
            /// Transformaing format to a STWSchema
            do {
                try transform(components: components)
            } catch let error as UITesting.TestError {
                throw error
            } catch {
                throw error
            }
        }
        
        /// MARK: - Private Helpers
        
        fileprivate func shouldMonitor(_ components: inout [String]) throws {
            
            // Checking if this navigation should be monitored
            guard let index = components.index(of: Key.action),
                (components.count - index) == Constants.monitorIndex,
                let last = components.last else { return }
            
            // Checking if the monitor tyoe is correct
            if last == Key.monitor {
                shouldMonitor = true
                components.removeLast()
            } else {
                throw TestError.error("Incorrect type: \(last)")
            }
        }
        
        fileprivate func setup(test: JSON) throws {
            if let stringAction = test[Key.action] as? String,
                let action = Action(rawValue: stringAction) {
                self.action = action
            }
            
            if let stringType = test[Key.type] as? String,
                let type = NavigationType(rawValue: stringType) {
                self.type = type
            } else {
                throw TestError.error("Navigation Type does not exists")
            }
            
            self.index = test[Key.index] as? Int
            self.key = test[Key.key] as? String ?? ""
            self.sequence = test[Key.order] as? Int ?? 0
            
            if let successorDictionary = test[Key.successor] as? [AnyHashable:Any] {
                do {
                    self.successor = try NavigationItem(dictionary: successorDictionary)
                } catch UITesting.TestError.error(let m) {
                    throw TestError.error(m)
                }
            }
        }
        
        fileprivate func convert(format: [String]) throws {
            
            /// Setting mutable format
            var format = format
            
            /// Assigning index
            guard let sequence = format.first?.toInt() else { throw TestError.error("STWSchema does not include a sequence index") }
            self.sequence = sequence
            
            /// Removing index
            format.removeFirst()
            
            /// Transformaing format to a STWSchema
            do {
                try transform(components: format)
            } catch let error as TestError {
                throw error
            } catch {
                throw error
            }
        }
        
        fileprivate func transform(components: [String]) throws {
            var components = components
            
            var elementType: NavigationType?
            var elementIndex: Int?
            var elementKey: String?
            
            var transforedIndex = 0
            
            for (index, format) in components.enumerated() {
                if let type = NavigationType(rawValue: format) {
                    if let _ = elementType {
                        transforedIndex = index - 1
                        break
                    } else {
                        elementType = type
                    }
                } else if let _index = format.toInt() {
                    if let _ = elementIndex {
                        transforedIndex = index - 1
                        break
                    } else {
                        elementIndex = _index
                    }
                } else if let action = Action(rawValue: format) {
                    self.action = action
                    transforedIndex = index
                    break
                } else {
                    elementKey = format
                    transforedIndex = index
                    break
                }
                
            }
            
            
            /// Setting up successors
            set(type: elementType, index: elementIndex, key: elementKey)
            
            if self.type == nil {
                throw TestError.error("Incorrect type: \(elementKey ?? "")")
            }
            
            /// Removing added successors
            for _ in 0...transforedIndex {
                components.removeFirst()
            }
            
            /// Setting next successor inline
            if !components.isEmpty {
                /// Transformaing format to a STWSchema
                do {
                    self.successor = try NavigationItem(components: components)
                } catch let error as TestError {
                    throw error
                } catch {
                    throw error
                }
            }
        }
        
        fileprivate func set(type: NavigationType?, index: Int?, key: String?) {
            if let type = type {
                self.type = type
            }
            
            self.index = index
            self.key = key
        }
    }
}
