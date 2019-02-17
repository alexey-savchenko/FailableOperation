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

class FailableSyncOperation<Input, Output> {
  typealias ResultHandler = (Result<Output>) -> Void
  typealias SyncOperation = (Input) -> Result<Output>
  private var attempts = 0
  private var maxAttempts: Int
  private let operation: SyncOperation
  
  init(_ maxAttempts: Int = 3, operation: @escaping SyncOperation) {
    self.maxAttempts = maxAttempts
    self.operation = operation
  }
  
  func execute(with input: Input, completion: ResultHandler) {
    attempts += 1
    let result = operation(input)
    if result.isFail && attempts < maxAttempts {
      execute(with: input, completion: completion)
    } else {
      completion(result)
    }
  }
}

// TODO: Move to structs and avoid mutation of retries var via instantiation of new instance of operation with updated retries value

class FailableAsyncOperation<Input, Output> {
  typealias ResultHandler = (Result<Output>) -> Void
  typealias AsyncOperation = (Input, (Result<Output>) -> Void) -> Void
  private var retries = 0
  private var maxRetries: Int
  private let operation: AsyncOperation
  
  init(_ maxRetries: Int = 3, operation: @escaping AsyncOperation) {
    self.maxRetries = maxRetries
    self.operation = operation
  }
  
  func execute(with input: Input, completion: ResultHandler) {
    retries += 1
    operation(input) { result in
      if result.isFail && retries < maxRetries {
        execute(with: input, completion: completion)
      } else {
        completion(result)
      }
    }
  }
}
