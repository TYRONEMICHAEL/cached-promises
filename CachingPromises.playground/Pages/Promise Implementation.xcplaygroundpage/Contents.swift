//: Playground - noun: a place where people can play

import UIKit
import Promises
import PlaygroundSupport
import XCTest

enum UserError: Error {
    case notFound
}

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
    func setCurrentUser(user: Promise<User>)
    func getCurrentUser() -> Promise<User>?
    func clear()
}

final class UserCacheImplementation: UserCache {
    
    private var userPromise: Promise<User>?
    
    func setCurrentUser(user: Promise<User>) {
        self.userPromise = user
    }
    
    func getCurrentUser() -> Promise<User>? {
        return self.userPromise ?? .none
    }
    
    func clear() {
        userPromise = .none
    }
    
}

let cacheImplementation = UserCacheImplementation()

protocol UserRepository {
    func getCurrentUser() -> Promise<User>
}

final class UserRepositoryImplementation: UserRepository {
    
    private var cache: UserCache {
        return cacheImplementation
    }
    
    private var delay: DispatchTime {
        return .now() + 3
    }
    
    func getCurrentUser() -> Promise<User> {
        if let existing = cache.getCurrentUser() { return existing }
        
        let user = Promise<User> { fulfill, reject in
            DispatchQueue.global(qos: .background).async {
                let user = self.dummyServiceCall()
                DispatchQueue.main.asyncAfter(deadline: self.delay) {
                    fulfill(user)
                }
            }
        }
        
        cache.setCurrentUser(user: user)
        user.catch(handle)
        return user
    }
    
    private func handle(error: Error) {
        cache.clear()
    }
    
    private func dummyServiceCall() -> User {
        guard !Thread.isMainThread else {
            fatalError()
        }
        return .unregistered
    }
    
    
    
}

//// VIEW SETUP

final class UserViewController: UIViewController {
    
    private var repository: UserRepository {
        return UserRepositoryImplementation()
    }
    
    private var promise: Promise<User>?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        render()
    }
    
    private func render() {
        showPendingState()
        repository.getCurrentUser().always(clearView)
            .then(showSuccessfulState)
            .catch(showErrorState)
    }
    
    private func clearView() {
        view.subviews.forEach { $0.removeFromSuperview() }
    }
    
    private func showPendingState() {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        indicator.center = view.center
        indicator.startAnimating()
        view.backgroundColor = .white
        view.addSubview(indicator)
    }
    
    private func showErrorState(error: Error) {
        let retryButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        retryButton.setTitle("Retry", for: UIControlState.normal)
        retryButton.addTarget(self, action: #selector(retryPressed), for: .touchDown)
        view.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        retryButton.center = view.center
        view.addSubview(retryButton)
    }
    
    private func showSuccessfulState(user: User) {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        label.text = "SUCCESS"
        label.textAlignment = .center
        label.center = view.center
        view.addSubview(label)
        view.backgroundColor = UIColor.green.withAlphaComponent(0.5)
    }
    
    @objc
    private func retryPressed() {
        promise = repository.getCurrentUser()
        render()
    }
    
}

func createTabItem(withIcon icon: UITabBarSystemItem) -> UINavigationController {
    let tabItem = UITabBarItem(tabBarSystemItem: icon, tag: 0)
    let navigationController = UINavigationController(rootViewController: UserViewController())
    navigationController.tabBarItem = tabItem
    return navigationController
}

let tab = UITabBarController()
tab.setViewControllers([
    createTabItem(withIcon: .downloads),
    createTabItem(withIcon: .history)
    ], animated: false)
PlaygroundPage.current.liveView = tab
PlaygroundPage.current.needsIndefiniteExecution = true



