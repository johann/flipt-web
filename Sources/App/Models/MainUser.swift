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
    var userId: String?
    var username: String = ""
    var password = ""
    var apiKeyID = URandom().secureToken
    var apiKeySecret = URandom().secureToken
    var profilePic = ""
    var email: String
    var fullname: String!
    var firstName: String!
    var lastName: String!
    var phoneNumber = ""
    

    static func authenticate(credentials: Credentials) throws -> User {
        var user: MainUser?
        
        switch credentials{
        case let credentials as UsernamePassword:
            print(credentials.username)
            print(credentials.password)
            let fetchedUser = try MainUser.query().filter("email", credentials.username).first()
            
            if let password = fetchedUser?.password,
                password != "",
                (try? BCrypt.verify(password: credentials.password, matchesHash: password)) == true {
                user = fetchedUser
                
            }
            
            
        case let credentials as Identifier:
            print(credentials)
            user = try MainUser.find(credentials.id)
            
        case let credentials as APIKey:
            user = try MainUser.query().filter("api_key_id", credentials.id).filter("api_key_secret", credentials.secret).first()
    
        default:
            throw UnsupportedCredentialsError()
        }
        
        if let user = user {
            return user
        }else{
            throw IncorrectCredentialsError()
        }
    }
    
    
    static func register(fullName: String, credentials: Credentials) throws -> User{
        var newUser: MainUser
    
        switch credentials {
        case let credentials as UsernamePassword:
            newUser = MainUser(credentials: credentials)

        default:
            throw UnsupportedCredentialsError()
        }
        
        if try MainUser.query().filter("email", newUser.username).first() == nil {
            
            let fullnameArray = fullName.components(separatedBy: " ")
            print(fullnameArray)
            if !fullnameArray.isEmpty {
                newUser.firstName = fullnameArray.first!
                newUser.lastName = fullnameArray.last ?? " "
            } else {
                // find better error to throw
                throw UnsupportedCredentialsError()
            }
            
        
            try newUser.save()
            
        }else{
            throw AccountTakenError()
        }


        return newUser
    }

    static func register(credentials: Credentials) throws -> User{
        var newUser: MainUser
        switch credentials {
        case let credentials as UsernamePassword:
            newUser = MainUser(credentials: credentials)
        default:
            throw UnsupportedCredentialsError()
        }
        
        
        if try MainUser.query().filter("email", newUser.username).first() == nil {
            try print(newUser.makeNode())
            
            try newUser.save()
         
            return newUser
        }else{
            throw AccountTakenError()
        }
    }
    
    //this is going to cause problems
    init(credentials: UsernamePassword) {
        self.email = credentials.username
        self.password = BCrypt.hash(password: credentials.password)
    }
    

    init(firstName:String, lastName:String, username:String) {
        self.userId = UUID().uuidString
        self.username = username
        self.apiKeyID = URandom().secureToken
        self.apiKeySecret = URandom().secureToken
        self.email = "test@example.com"
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = "12342342345"
        self.profilePic = "johann.png"
        self.password = "password"
    }
    
    
    init(node: Node, in context: Context) throws {
        self.id = node["id"]
        self.userId = try node.extract("userid")
        self.email = try node.extract("email")
        self.username = try node.extract("username")
        self.password = try node.extract("password")
        self.apiKeyID = try node.extract("api_key_id")
        self.apiKeySecret = try node.extract("api_key_secret")
        self.profilePic = try node.extract("profilepic") ?? ""
        self.phoneNumber = try node.extract("phonenumber")
        self.firstName = try node.extract("firstname")
        self.lastName = try node.extract("lastname")
        
    }
    
    func makeNode(context: Context) throws -> Node {
        // let books = try self.books()
        return try Node(node:[
            MainUser.idKey :id,
            MainUser.emailKey: email,
            MainUser.userNameKey: username,
            MainUser.passwordKey: password,
            MainUser.apiKey:apiKeyID,
            MainUser.apiSecret: apiKeySecret,
            MainUser.phonenumberKey:phoneNumber,
            MainUser.profilePic: profilePic,
            MainUser.firstnameKey: firstName,
            MainUser.lastnameKey: lastName,
            "userid":userId
            ])
    }
    
    
    static func prepare(_ database: Database) throws {
        try database.create("mainusers"){ users in
            users.id()
            users.string(MainUser.emailKey)
            users.string(MainUser.userNameKey, length: 255, optional: true)
            users.string(MainUser.passwordKey)
            users.string(MainUser.apiKey)
            users.string(MainUser.apiSecret)
            users.string(MainUser.profilePic, length: 255, optional: true)
            users.string(MainUser.phonenumberKey, length: 255, optional: true)
            users.string(MainUser.firstnameKey, length: 255, optional: true)
            users.string(MainUser.lastnameKey, length: 255, optional: true)
            users.string(MainUser.userId, length: 255, optional: true)
       
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
    
    func books() throws -> [Book] {
        let books = try children(nil, Book.self).all()
        return books
    }
    // fix
    func mybooks() throws -> [Book]{
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
    
   
    
    static func getRandomId() throws -> Node? {
        let users = try MainUser.query().all()
        let randomIndex: Int
        #if os(Linux)
            randomIndex = Int(random() % (users.count + 1))
        #else
            randomIndex = Int(arc4random_uniform(UInt32(users.count)))
        #endif
    
        if !users.isEmpty {
           
            return Node(randomIndex)
            
        } else {
            return Node(1)
        }
        
    }
}
extension MainUser {
    static let userId = "userid"
    static let emailKey = "email"
    static let idKey = "id"
    static let userNameKey = "username"
    static let passwordKey = "password"
    static let apiKey = "api_key_id"
    static let apiSecret = "api_key_secret"
    static let profilePic = "profilepic"
    static let phonenumberKey = "phonenumber"
    static let firstnameKey = "firstname"
    static let lastnameKey = "lastname"
    
}
