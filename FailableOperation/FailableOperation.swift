//
//  FailableOperation.swift
//  FailableOperation
//
//  Created by Alexey Savchenko on 2/17/19.
//  Copyright © 2019 Alexey Savchenko. All rights reserved.
//

import Foundation

enum Result<T> {
  case success(T)
  case fail(Error)
  
  var isFail: Bool {
    switch self {
    case .fail:
      return true
    case .success:
      return false
    }
  }
  
  var isSuccess: Bool {
    switch self {
    case .fail:
      return false
    case .success:
      return true
    }
  }
}

struct FailableSyncOperation<Input, Output> {
  
  typealias ResultHandler = (Result<Output>) -> Void
  typealias SyncOperation = (Input) -> Result<Output>
  
  private var attempts = 0
  private let maxAttempts: Int
  private let wrapped: SyncOperation
  private let queue: DispatchQueue?
  private let retryDelay: TimeInterval?
  
  init(_ maxAttempts: Int = 2,
       queue: DispatchQueue? = nil,
       retryDelay: TimeInterval? = nil,
       operation: @escaping SyncOperation) {
    
    self.maxAttempts = maxAttempts
    self.wrapped = operation
    self.queue = queue
    self.retryDelay = retryDelay
  }
  
  func execute(with input: Input, completion: @escaping ResultHandler) {
    (queue ?? .main).asyncAfter(deadline: .now()) {
      let result = self.wrapped(input)
      if result.isFail && self.attempts < self.maxAttempts {
        (self.queue ?? .main).asyncAfter(deadline: .now() + (self.retryDelay ?? 0), execute: {
          self.spawnOperation(with: self.attempts + 1).execute(with: input, completion: completion)
        })
      } else {
        completion(result)
      }
    }
  }
  
  private func spawnOperation(with attempts: Int) -> FailableSyncOperation<Input, Output> {
    var op = FailableSyncOperation(maxAttempts, queue: queue, retryDelay: retryDelay, operation: wrapped)
    op.attempts = attempts
    return op
  }
}

struct FailableAsyncOperation<Input, Output> {
  
  typealias ResultHandler = (Result<Output>) -> Void
  typealias AsyncOperation = (Input, (Result<Output>) -> Void) -> Void
  
  private var attempts = 0
  private let maxAttempts: Int
  private let wrapped: AsyncOperation
  private let queue: DispatchQueue?
  private let retryDelay: TimeInterval?
  
  init(_ maxAttempts: Int = 2,
       queue: DispatchQueue? = nil,
       retryDelay: TimeInterval? = nil,
       operation: @escaping AsyncOperation) {
    
    self.maxAttempts = maxAttempts
    self.wrapped = operation
    self.queue = queue
    self.retryDelay = retryDelay
  }
  
  func execute(with input: Input, completion: @escaping ResultHandler) {
    (queue ?? .main).asyncAfter(deadline: .now()) {
      self.wrapped(input) { result in
        if result.isFail && self.attempts < self.maxAttempts {
          (self.queue ?? .main).asyncAfter(deadline: .now() + (self.retryDelay ?? 0), execute: {
            self.spawnOperation(with: self.attempts + 1).execute(with: input, completion: completion)
          })
        } else {
          completion(result)
        }
      }
    }
  }
  
  private func spawnOperation(with attempts: Int) -> FailableAsyncOperation<Input, Output> {
    var op = FailableAsyncOperation(maxAttempts, queue: queue, retryDelay: retryDelay, operation: wrapped)
    op.attempts = attempts
    return op
  }
}
