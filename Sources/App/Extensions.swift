//
//  Extensions.swift
//  Flipt-web
//
//  Created by Johann Kerr on 2/24/17.
//
//

import Foundation
import Vapor
import Fluent
import Turnstile
import TurnstileCrypto
import TurnstileWeb


//class EmailUsernamePassword: UsernamePassword {
//    var email: String
//    
//    public init(email: String, username: String, password: String) {
//        self.email = email
//        super.init(username: username, password: password)
//    }
//}

public struct EmailTakenError: CredentialsError {
    /// Empty initializer for AccountTakenError
    public init() {}
    
    /// User-presentable error message
    public let description = "The account is already registered."
}

public struct InvalidCredentials: CredentialsError {
    /// Empty initializer for AccountTakenError
    public init() {}
    
    /// User-presentable error message
    public let description = "Invalid Credentials Supplied"
}


public struct UsernameTakenError: CredentialsError {
    /// Empty initializer for AccountTakenError
    public init() {}
    
    /// User-presentable error message
    public let description = "This username has been taken."
}
