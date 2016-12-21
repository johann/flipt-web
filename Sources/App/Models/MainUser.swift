//
//  MainUser.swift
//  Flipt-web
//
//  Created by Johann Kerr on 11/30/16.
//
//

import Foundation
import HTTP
import Fluent
import Turnstile
import TurnstileCrypto
import TurnstileWeb
import Auth

final class MainUser: User{
    var exists: Bool = false
    var id: Node?
    
    var username: String
    var password = ""
    var apiKeyID = URandom().secureToken
    var apiKeySecret = URandom().secureToken
    var profilePic = ""
    
    
    static func authenticate(credentials: Credentials) throws -> MainUser {
        var user: MainUser?
               
        switch credentials{
            
        case let credentials as UsernamePassword:
            let fetchedUser = try MainUser.query().filter("username", credentials.username).first()
            
            if let password = fetchedUser?.password,
                password != "",
                (try? BCrypt.verify(password: credentials.password, matchesHash: password)) == true {
                user = fetchedUser
                
            }
            
            
        case let credentials as Identifier:
            user = try MainUser.find(credentials.id)
        case let credentials as APIKey:
//            print(credentials.id)
//            print(credentials.secret)
            //user = try MainUser.query().filter("api_key_id", credentials.id).filter("api_key_secret", credentials.secret).first()
            user = try MainUser.query().filter("api_key_id", credentials.id).first()
        default:
            throw UnsupportedCredentialsError()
        }
        
        if let user = user {
            return user
        }else{
            throw IncorrectCredentialsError()
        }
    }
    
    static func register(credentials: Credentials) throws -> User{
        var newUser: MainUser
        switch credentials {
        case let credentials as UsernamePassword:
            newUser = MainUser(credentials: credentials)
        default:
            throw UnsupportedCredentialsError()
        }
        
        
        if try MainUser.query().filter("username", newUser.username).first() == nil {
            try print(newUser.makeNode())
            print("not saved")
            try newUser.save()
            print("saved")
            return newUser
        }else{
            throw AccountTakenError()
        }
    }
    
    
    init(credentials: UsernamePassword){
        self.username = credentials.username
        self.password = BCrypt.hash(password: credentials.password)
    }
    
    
    init(node: Node, in context: Context) throws {
        self.id = node["id"]
        self.username = try node.extract("username")
        self.password = try node.extract("password")
        self.apiKeyID = try node.extract("api_key_id")
        self.apiKeySecret = try node.extract("api_key_secret")
        self.profilePic = try node.extract("profilepic") ?? ""
        
    }
    
    func makeNode(context: Context) throws -> Node{
       // let books = try self.books()
        return try Node(node:[
            MainUser.idKey :id,
            MainUser.userNameKey: username,
            MainUser.passwordKey: password,
            MainUser.apiKey:apiKeyID,
            MainUser.apiSecret: apiKeySecret,
            "profilepic": profilePic
            ])
    }
    
   
    static func prepare(_ database: Database) throws {
        try database.create("mainusers"){ users in
            users.id()
            users.string(MainUser.userNameKey)
            users.string(MainUser.passwordKey)
            users.string(MainUser.apiKey)
            users.string(MainUser.apiSecret)
            users.string("profilepic")
        }
    }
    
    static func revert(_ database:Database) throws {
        try database.delete("mainusers")
    }
    
}

extension Request {
    
    func user() throws -> MainUser {
        
        guard let user = try auth.user() as? MainUser else {
            throw "Invalid user type"
        }
        return user
    }
}

extension String: Error {}

extension MainUser{
    // fix
    func books() throws -> [Book]{
        if let userId = id {
            let books = try Book.query().filter("mainuser_id", userId).all()
            if books.isEmpty {
                return []
            } else {
                return books
            }
        }else {
            return []
        }
        
    }
}
extension MainUser {
    static let idKey = "id"
    static let userNameKey = "username"
    static let passwordKey = "password"
    static let apiKey = "api_key_id"
    static let apiSecret = "api_key_secret"
}
