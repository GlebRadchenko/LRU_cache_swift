//
//  LRUCache.swift
//  LRUCache
//
//  Created by Gleb on 9/6/17.
//  Copyright © 2017 Gleb. All rights reserved.
//

import Foundation

//Can be replaced with doubly linked list or queue
class PriorityTree<K: Equatable, V: Comparable> {
    class Node<K: Equatable, V: Comparable> {
        var key: K
        var value: V
        
        var left: Node<K, V>?
        var right: Node<K, V>?
        
        var size: Int {
            return (left?.size ?? 0) + 1 + (right?.size ?? 0)
        }
        
        var smallerExist: Bool {
            return left != nil
        }
        
        var biggerExist: Bool {
            return right != nil
        }
        
        init(k: K, v: V) {
            key = k
            value = v
        }
        
        func extractMin() -> Node<K, V>? {
            guard let left = left else {
                return nil
            }
            
            if !left.smallerExist {
                self.left = left.right
                return left
            }
            
            return left.extractMin()
        }
        
        func extractMax() -> Node<K, V>? {
            guard let right = right else {
                return nil
            }
            
            if !right.biggerExist {
                self.right = right.left
                return right
            }
            
            return right.extractMax()
        }
        
        func insert(_ node:  Node<K, V>) {
            if node.key == key { return }
            
            if node.value < value {
                guard let left = left else {
                    self.left = node
                    return
                }
                left.insert(node)
            } else {
                guard let right = right else {
                    self.right = node
                    return
                }
                right.insert(node)
            }
        }
        
        func insert(_ node: Node<K, V>?) {
            guard let node = node else { return }
            insert(node)
        }
        
        func containsNode(with key: K) -> Bool {
            if self.key == key {
                return true
            } else {
                return left?.containsNode(with: key) == true || right?.containsNode(with: key) == true
            }
        }
        
        func updateNode(with key: K, newValue: V) -> Node<K, V>? {
            if self.key == key {
                value = newValue
                return self
            } else {
                if let leftUpdated = left?.updateNode(with: key, newValue: newValue) {
                    if let rightChild = leftUpdated.right {
                        left = rightChild
                        left?.insert(leftUpdated.left)
                    } else if let leftChild = leftUpdated.left {
                        left = leftChild
                    }
                    
                    leftUpdated.left = nil
                    leftUpdated.right = nil
                    
                    return leftUpdated
                }
                
                if let rightUpdated = right?.updateNode(with: key, newValue: newValue) {
                    if let leftChild = rightUpdated.left {
                        right = leftChild
                        right?.insert(rightUpdated.right)
                    } else if let rightChild = rightUpdated.right {
                        right = rightChild
                    }
                    
                    rightUpdated.left = nil
                    rightUpdated.right = nil
                    
                    return rightUpdated
                }
                
                return nil
            }
        }
    }
    
    var root: Node<K, V>?
    var size: Int {
        return root?.size ?? 0
    }
    
    func insert(key: K, value: V) {
        insert(node: Node<K, V>(k: key, v: value))
    }
    
    func insert(node: Node<K, V>) {
        guard let root = root else {
            self.root = node
            return
        }
        root.insert(node)
    }
    
    func containsNode(with key: K) -> Bool {
        return root?.containsNode(with: key) ?? false
    }
    
    func updateNode(with key: K, newValue: V) {
        if root?.key == key {
            let updated = root
            updated?.value = newValue
            
            if let leftChild = updated?.left {
                root = leftChild
                root?.insert(updated?.right)
            } else if let rightChild = root?.right {
                root = rightChild
                root?.insert(updated?.left)
            }
            
            updated?.left = nil
            updated?.right = nil
            
            root?.insert(updated)
        } else {
            let updatedNode = root?.updateNode(with: key, newValue: newValue)
            root?.insert(updatedNode)
        }
    }
    
    func extractMin() -> Node<K, V>? {
        guard let root = root else { return nil }
        
        if !root.smallerExist {
            self.root = root.right
            return root
        }
        
        return root.extractMin()
    }
    
    func extractMax() -> Node<K, V>? {
        guard let root = root else { return nil }
        if !root.biggerExist {
            self.root = root.left
            return root
        }
        
        return root.extractMax()
    }
}

class LRUCache<K: Hashable, V> {
    var cacheSize: Int
    var calculate: (_ key: K) -> V
    
    private var table: [K: V]
    private var priorityTree: PriorityTree<K, Date>
    
    init(size: Int, _ calculate: @escaping (_ key: K) -> V) {
        table = [:]
        priorityTree = PriorityTree<K, Date>()
        cacheSize = size
        self.calculate = calculate
    }
    
    func value(for key: K) -> V {
        let currentTime = Date()
        
        if let value = table[key] {
            priorityTree.updateNode(with: key, newValue: currentTime)
            return value
        }
        
        let value = calculate(key)
        
        if priorityTree.size == cacheSize {
            if let extracted = priorityTree.extractMin() {
                table.removeValue(forKey: extracted.key)
                print("Extract: ", extracted)
            }
        }
        
        table[key] = value
        priorityTree.insert(key: key, value: currentTime)
        
        return value
    }
}

class AsyncLRUCache<K: Hashable, V> {
    var cacheSize: Int
    var calculate: (_ key: K, _ completion: @escaping (_ value: V) -> Void) -> Void
    
    private var table: [K: V]
    private var priorityTree: PriorityTree<K, Date>
    private lazy var serialQueue: DispatchQueue = DispatchQueue(label: "async-lru-cache-queue")
    
    init(size: Int, _ calculate: @escaping (K, @escaping (V) -> Void) -> Void ) {
        table = [:]
        priorityTree = PriorityTree<K, Date>()
        cacheSize = size
        self.calculate = calculate
    }
    
    func value(for key: K, completion: @escaping (_ value: V) -> Void) {
        serialQueue.sync { [weak self] in
            guard let wSelf = self else { return }
            
            let currentTime = Date()
            if let value = wSelf.table[key] {
                wSelf.serialQueue.async {
                    completion(value)
                }
                wSelf.priorityTree.updateNode(with: key, newValue: currentTime)
                return
            }
            
            wSelf.calculate(key) { (value) in
                completion(value)
                wSelf.serialQueue.sync {
                    if wSelf.priorityTree.size == wSelf.cacheSize {
                        if let extracted = wSelf.priorityTree.extractMin() {
                            wSelf.table.removeValue(forKey: extracted.key)
                            print("Extract: ", extracted)
                        }
                    }
                    
                    wSelf.table[key] = value
                    wSelf.priorityTree.insert(key: key, value: currentTime)
                }
            }
        }
    }
}
