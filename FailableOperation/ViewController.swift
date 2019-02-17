//
//  ViewController.swift
//  FailableOperation
//
//  Created by Alexey Savchenko on 2/17/19.
//  Copyright © 2019 Alexey Savchenko. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
    struct SomeError: Error {
      
    }
    
    let sync = FailableSyncOperation<Void, Int> { _ in
      if arc4random_uniform(10) < 5 {
        print("Sync operation fail")
        return Result.fail(SomeError())
      } else {
        print("Sync operation success")
        return Result.success(42)
      }
    }
    
    sync.execute(with: ()) { (result) in
      print("Result of failable sync operaion - \(result)")
    }
    
    func someAsyncFunction(_ completion: ((Result<Int>) -> Void)) {
      if arc4random_uniform(10) < 5 {
        print("Async operation fail")
        completion(.fail(SomeError()))
      } else {
        print("Async operation success")
        completion(.success(42))
      }
    }
    
    let async = FailableAsyncOperation<Void, Int> { (input, handler) in
      someAsyncFunction(handler)
    }
    
    async.execute(with: ()) { (result) in
      print("Result of failable async operaion - \(result)")
    }
  }
}
