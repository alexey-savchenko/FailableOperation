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
  case failure(Error)
  
  var isFailure: Bool {
    switch self {
    case .failure:
      return true
    case .success:
      return false
    }
  }
  
  var isSuccess: Bool {
    switch self {
    case .failure:
      return false
    case .success:
      return true
    }
  }
}

struct FallibleSyncOperation<Input, Output> {
  
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
      if result.isFailure && self.attempts < self.maxAttempts {
        (self.queue ?? .main).asyncAfter(deadline: .now() + (self.retryDelay ?? 0), execute: {
          self.spawnOperation(with: self.attempts + 1).execute(with: input, completion: completion)
        })
      } else {
        completion(result)
      }
    }
  }
  
  private func spawnOperation(with attempts: Int) -> FallibleSyncOperation<Input, Output> {
    var op = FallibleSyncOperation(maxAttempts, queue: queue, retryDelay: retryDelay, operation: wrapped)
    op.attempts = attempts
    return op
  }
}

struct FallibleAsyncOperation<Input, Output> {
  
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
        if result.isFailure && self.attempts < self.maxAttempts {
          (self.queue ?? .main).asyncAfter(deadline: .now() + (self.retryDelay ?? 0), execute: {
            self.spawnOperation(with: self.attempts + 1).execute(with: input, completion: completion)
          })
        } else {
          completion(result)
        }
      }
    }
  }
  
  private func spawnOperation(with attempts: Int) -> FallibleAsyncOperation<Input, Output> {
    var op = FallibleAsyncOperation(maxAttempts, queue: queue, retryDelay: retryDelay, operation: wrapped)
    op.attempts = attempts
    return op
  }
}
