//: Playground - noun: a place where people can play

import UIKit
import Promises
import PlaygroundSupport
import XCTest

struct UserProfile {
    let name: String
    let email: String
}

enum User {
    case admin(UserProfile)
    case registered(UserProfile)
    case unregistered
}

protocol UserCache {
    func setCurrentUser(user: User)
    func getCurrentUser() -> User?
}

final class UserCacheImplementation: UserCache {
    
    private var user: User?
    
    func setCurrentUser(user: User) {
        self.user = user
    }
    
    func getCurrentUser() -> User? {
        return self.user ?? .none
    }
    
}

let userCache: UserCache = UserCacheImplementation()

protocol UserRepository {
    func getCurrentUser() -> User
}

final class UserRepositoryImplementation: UserRepository {
    
    let cache = userCache
    
    func getCurrentUser() -> User {
        if let user = cache.getCurrentUser() {
            return user
        }
        return dummyServiceCall()
    }
    
    private func dummyServiceCall() -> User {
        // Usually done in the networking layer
        guard !Thread.isMainThread else {
            fatalError()
        }
        let user: User = .unregistered
        cache.setCurrentUser(user: user)
        return user
    }
    
}

DispatchQueue.global(qos: .background).async {
    let user = UserRepositoryImplementation().getCurrentUser()
    DispatchQueue.main.async {
        dump(user)
    }
}

PlaygroundPage.current.needsIndefiniteExecution = true
