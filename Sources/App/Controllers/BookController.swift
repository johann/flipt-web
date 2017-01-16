//
//  BookController.swift
//  Flipt-web
//
//  Created by Johann Kerr on 11/21/16.
//
//

import Foundation
import Vapor
import HTTP

final class BookController{
    

    
    func addRoutes(drop: Droplet){
        drop.get("books", handler: index)
    }
    
    
    func index(request: Request) throws -> ResponseRepresentable{
        return try JSON(node: Book.all().makeNode())
    }
    
   
    
    
    
    
}
