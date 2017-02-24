//
//  UserController.swift
//  Flipt-web
//
//  Created by Johann Kerr on 12/1/16.
//
//

import Foundation
import Vapor
import Auth
import HTTP
import Cookies
import Turnstile
import TurnstileCrypto
import TurnstileWeb
import Fluent



final class UserController{
    
    func addRoutes(drop: Droplet){
        drop.get("users", handler: index)
        drop.get("login", handler: login)
        drop.post("login", handler:loginData)
        drop.get("register", handler: register)
        drop.post("register", handler:registerData)
        drop.post("logout", handler:logout)
    }
    
    func bookIndex(request: Request) throws -> ResponseRepresentable{
        

        return try JSON(node: MainUser.all().makeNode())
    }
    
    
    
    func index(request: Request) throws -> ResponseRepresentable{
        return try JSON(node: MainUser.all().makeNode())
    }
    
    func register(request: Request) throws -> ResponseRepresentable{
        return try drop.view.make("register")
    }
    
    func login(request: Request) throws -> ResponseRepresentable{
        return try drop.view.make("login")
    }
    
   
    
    func registerData(request: Request) throws -> ResponseRepresentable{
        guard let email = request.formURLEncoded?["email"]?.string,
            let password = request.formURLEncoded?["password"]?.string, let fullname = request.formURLEncoded?["fullname"]?.string, let username = request.formURLEncoded?["username"]?.string else {
                return try drop.view.make("register", ["flash": "Missing email or password"])
        }
        
        let credentials = UsernamePassword(username: email, password: password)
        
        do {
            _ = try MainUser.register(fullName: fullname, username: username, credentials: credentials)
       
            print(credentials.username)
            print(credentials.password)
            //try request.auth.login(<#T##credentials: Credentials##Credentials#>)
           try request.auth.login(credentials, persist: true)
            //change response
            return Response(redirect: "/")
        } catch let e as TurnstileError {
            return try drop.view.make("register", Node(node: ["flash": e.description]))
        }
        
    }
    
    func loginData(request: Request) throws -> ResponseRepresentable{
        guard let email = request.formURLEncoded?["email"]?.string,
            let password = request.formURLEncoded?["password"]?.string else {
                return try drop.view.make("login", ["flash": "Missing username or password"])
        }
        let credentials = UsernamePassword(username: email, password: password)
        do {
            try _ = MainUser.authenticate(credentials: credentials)
            try request.auth.login(credentials)
            return Response(redirect: "/")
        } catch _ {
            return try drop.view.make("login", ["flash": "Invalid username or password"])
        }
    }
    
    func logout(request: Request) throws -> ResponseRepresentable{
            request.subject.logout()
            return Response(redirect: "/")
    }
    
    
    
}


