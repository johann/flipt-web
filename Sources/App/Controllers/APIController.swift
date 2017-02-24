//
//  APIController.swift
//  Flipt-web
//
//  Created by Johann Kerr on 12/5/16.
//
//

import Foundation
import PostgreSQL
import Vapor
import Auth
import HTTP
import Cookies
import Turnstile
import TurnstileCrypto
import TurnstileWeb
import Fluent


//user/books -> GET my books
//add book -> POST add book
//books/search -> Get search
//sendbook -> POST send as data bookid and recipient
//book/:bookid  -> POST update book send data
//user -> GET get user
//books/near -> GET near books
//user/:userid -> GET user
//updatePic -> POST update profilePicture
//user -> POST update user


final class APIController {
    
    let protect = ProtectMiddleware(error: Abort.custom(status: .unauthorized, message: "Unauthorized"))
    
    
    
    func addRoutes(drop:Droplet){
        drop.grouped(BasicAuthenticationMiddleware(), protect).group("api") { api in
            //Books
            
            api.get("user", "books", handler: myBooks) //should be books/me
            api.post("book", handler: addBook)
            api.get("books","search", handler:search)
            api.post("sendbook", handler:sendBook)
            api.post("book", String.self) { request, bookId in
                try self.updateBook(request: request, bookId: bookId)
                
            }
            api.get("book", String.self) { request, bookId in
                try self.findBookBy(id: bookId)
            }

            api.get("user", handler: respond)
            api.get("books","near", handler:near)
            api.get("user", String.self) { request, userId in
                
                try self.findUsersBy(request:request, userID: userId)
            }
            api.post("updatePic", handler: updateProfilePicture) //create update for user
            
            api.post("user", handler: updateUser)
            // POST Request with Data
          
            
        }
        
        drop.group("api"){ api in
            api.post("register", handler: registerJSON)
            api.post("login", handler: loginJSON)
        }
        
    }

    func updateUser(request: Request) throws -> ResponseRepresentable {

        var user = try request.user()
        request.data["userid"]?.string.map{ user.userId = $0 }
        request.data["username"]?.string.map{ user.username = $0 }
        request.data["profilePic"]?.string.map{ user.profilePic = $0 }
        request.data["email"]?.string.map{ user.email = $0 }
        request.data["firstName"]?.string.map{ user.firstName = $0 }
        request.data["lastName"]?.string.map{ user.lastName = $0 }
        request.data["phoneNumber"]?.string.map{ user.phoneNumber = $0 }
        user.fullname = user.firstName + " " + user.lastName
        try user.save()
        return try JSON(node:["success":"ok"])
        
    }
    ///find way to check for nothing sent
    func updateBook(request: Request, bookId:String) throws -> ResponseRepresentable {
        //get the right book from user
    
        var book = try request.user().books().filter({ $0.bookId == bookId }).first
        
        request.data["title"]?.string.map{ book?.title = $0 }
        request.data["imgurl"]?.string.map{ book?.imgUrl = $0 }
        request.data["latitude"]?.double.map{ book?.lat = $0 }
        request.data["longitude"]?.double.map{ book?.long = $0 }
        request.data["publisher"]?.string.map{ book?.publisher = $0 }
        request.data["author"]?.string.map{ book?.author = $0 }
        request.data["description"]?.string.map{ book?.description = $0 }
        request.data["publishYear"]?.string.map{ book?.publishYear = $0 }
        request.data["userimg"]?.string.map{ book?.userImg = $0 }
        try book?.save()
        
        return try JSON(node:["success":"ok"])
    }
    
    
    
    func sendBook(request: Request) throws -> ResponseRepresentable {
        //get the right book from user
        let bookId = request.data["bookid"]?.string ?? ""
        var book = try request.user().books().filter({ $0.bookId == bookId }).first
        guard let recipient = request.data["recipient"]?.string else {
            return "Bad Request"
        }
        
        let user = try MainUser.query().filter("userid", recipient).all().first
     
        book?.mainuser_id = user?.id
        try book?.save()
        
        return try JSON(node:["success":"ok"])
    }

    
    func getBooks(request: Request, user: MainUser) throws -> ResponseRepresentable {
        
        return try JSON(node: user.books().makeNode())
    }
    
    
    //Route Functions
    
    func respond(request: Request) throws -> ResponseRepresentable{
        //        let userId = try request.user().id?.int ?? 0
        //
    
        let userId = try request.user().id?.int
        
        let booksCount = try Book.query().filter("mainuser_id", userId!).all().count
        print(booksCount)
        //        print(booksCount)
        
        return try JSON(node: ["user":request.user().makeNode(),
                               "books":booksCount])
    }
    
    
    
}

//MARK:- Login

extension APIController {
    //MARK:- Register
//    var userId: String?
//    var username: String = ""
//    var password = ""
//    var apiKeyID = URandom().secureToken
//    var apiKeySecret = URandom().secureToken
//    var profilePic = ""
//    var email: String
//    var fullname: String!
//    var firstName: String!
//    var lastName: String!
//    var phoneNumber = ""
    
    
    func registerJSON(request: Request) throws -> ResponseRepresentable{
        
        guard let email = request.json?["email"]?.string, let password = request.json?["password"]?.string else {
            throw Abort.badRequest
        }
        
        
        
        let username = request.data["username"]?.string ?? ""
        let profilePic = request.data["profilePic"]?.string ?? ""
        let fullName = request.data["fullname"]?.string ?? ""
        let userid = request.data["userid"]?.string ?? ""
        var firstName = ""
        var lastName = ""
        if !fullName.isEmpty {
            let fullNameArray = fullName.components(separatedBy: " ")
            firstName = fullNameArray.first!
            lastName = fullNameArray.last ?? ""
            
        }
        let phoneNumber = request.data["phoneNumber"]?.string ?? ""
        
       // let credentials = UsernamePassword(username: email, password: password)
       
        
            
            do {
                
                if !(username == "") && !(email == "") && !(password == "") {
                    print("email - \(email)")
                    print("username - \(username)")
                    let credentials = UsernamePassword(username: email, password: password)
                    var user = try MainUser.register(fullName: fullName, username: username, credentials: credentials) as! MainUser
                    // var user = try MainUser.register(credentials: credentials) as! MainUser
                    try request.auth.login(credentials)
                    user.username = username
                    user.fullname = fullName
                    user.firstName = firstName
                    user.lastName = lastName
                    user.phoneNumber = phoneNumber
                    user.userId = userid
                    user.profilePic = profilePic
                    try user.save()
                    return try JSON(node: ["status": "ok", "user":user.makeNode()] )
                } else {
                    throw InvalidCredentials()
                }
                
            } catch let e as TurnstileError {
                print(e.description)
                return try JSON(node:["status": e.description])
            }
       
        
        
       
        
    }
    
    //MARK:- Login
    func loginJSON(request: Request) throws -> ResponseRepresentable{
        guard let email = request.json?["email"]?.string, let password = request.json?["password"]?.string else {
            throw Abort.badRequest
        }
        

        let credentials = UsernamePassword(username: email, password: password)
        
        do {
            let user = try MainUser.authenticate(credentials: credentials)
            try request.auth.login(credentials)
            return try JSON(node: ["status":"ok",
                                   "user": try user.makeNode()
                ])
            
        } catch let e {
            
            return try JSON(node: ["status": e.localizedDescription] )
        }
        
    }
}

//MARK:- User Management

extension APIController {
    func updateProfilePicture(request:Request) throws -> ResponseRepresentable{
        var success = false
        guard let profilePicture = request.json?["profilePic"]?.string else {
            throw Abort.badRequest
        }
        let user = try request.user()
        
        let foundUser = try MainUser.query().filter("username", user.username).first()
        
        guard let myUser = foundUser else {
            return Abort.badRequest as! ResponseRepresentable
        }
        
        var updatedUser = myUser
        updatedUser.profilePic = profilePicture
        try updatedUser.save()
        do {
            try updatedUser.save()
            success = true
        }catch {
            success = false
        }
        
        return try JSON(node:["success":success])
        
    }
}


//MARK:- Books

extension APIController {
    //MARK:- User Books
    
    
    func findBookBy(id:String) throws -> ResponseRepresentable {
        guard let book = try Book.query().filter("bookid", id).all().first else {
            return "Book Not Found"
        }
        
        return try JSON(node: book.makeNode())
    }
    

//    http://localhost:8080/api/user/2?type=id
//    http://localhost:8080/api/user/2?type=userid

    
    func findUsersBy(request:Request, userID id:String) throws -> ResponseRepresentable {
        print("running")
        guard let queryType = request.query?["type"]?.string else {
            return "No query submitted"
        }
        let user: MainUser!
        
        if queryType == "userid" {
            guard let user = try MainUser.query().filter("userid", id).first() else {
                return "User Not Found"
            }
            let books = try user.books()
            var node = try Node(["books":books.makeNode()])
            node["user"] = try user.makeNode()
            return try JSON(node: node)
        } else if queryType == "id" {
            guard let user = try MainUser.query().filter("id", id).first() else {
                return "User Not Found"
            }
            let books = try user.books()
            var node = try Node(["books":books.makeNode()])
            node["user"] = try user.makeNode()
            return try JSON(node: node)
        } else {
            return "No query"
        }

    }
    func userbooks(request:Request, id:Int) throws -> ResponseRepresentable{
        let books = try Book.query().filter("mainuser_id", id).all()
        
        return try JSON(node: books.makeNode())
    }
    
    //MARK:- Add Book
    
    func addBook(request: Request) throws -> ResponseRepresentable{
        
        guard let isbn = request.data["isbn"]?.string else {
            return try JSON(node: ["status":"ISBN Missing"])
        }

        let user = try request.user()
        let books = try user.books()
//        let isbnCheck =  books.contains(where: { (book) -> Bool in
//            if book.isbn == isbn {
//                return true
//            } else {
//                return false
//            }
//        })
        //let isbnCheck = try MainUser.query().filter("isbn",  isbn).all().isEmpty
        // checking if user already has the book
       
            let title = request.data["title"]?.string ?? ""
            let imgUrl = request.data["imgUrl"]?.string ?? ""
            let latitude = request.data["latitude"]?.double ?? 0.0
            let longitude = request.data["longitude"]?.double ?? 0.0
            let publisher = request.data["publisher"]?.string ?? ""
            let author = request.data["author"]?.string ?? ""
            let description = request.data["description"]?.string ?? ""
            let publishYear = request.data["publishYear"]?.string ?? ""
            let owner = try request.user()
            var book = Book(title: title, isbn: isbn, imgUrl: imgUrl, lat: latitude, long: longitude, mainuser_id: owner.id!, publisher: publisher, author: author, description: description, publishYear: publishYear)
            
            try book.save()
            
            return try JSON(node: book.makeNode())
//        } else {
//            return try JSON(node: ["status":"Book Already Exists"])
//        }
        
        
        
        
        
    }
    
    //MARK:- Get Books
    func myBooks(request: Request) throws -> ResponseRepresentable{
        let user = try request.user()
        
        
        //        if let userId = user.id{
        //
        //            let books = try Book.query().filter("mainuser_id", userId).all()
        //            return try JSON(node: books.makeNode())
        //        }
        
        return try JSON(node: user.books().makeNode())
    }
    
    //MARK:- Near
    
    func near(request:Request) throws -> ResponseRepresentable{
        // 40.719503, -73.985142
        let user = try request.user()
        guard let userId = user.id else { return Abort.badRequest as! ResponseRepresentable }
        guard let userInt = userId.int else { return Abort.badRequest as! ResponseRepresentable }
        
        
        
        var latitudeRadians = 0.0
        var longitudeRadians = 0.0
        if let latitude = request.data["lat"]?.double, let longitude = request.data["long"]?.double {
            latitudeRadians = latitude * M_PI/180
            longitudeRadians = longitude * M_PI/180
        }
        
        var foundbooks = [Book]()
        
        findBooks(userId: userInt, within: 1609, from: latitudeRadians, longitude: longitudeRadians) { (books) in
            foundbooks = books
        }
        
        return try JSON(node: foundbooks.makeNode())
    }
    
    //MARK:- Search
    func search(request: Request) throws -> ResponseRepresentable{
        
        if let titlesearch = request.data["title"]?.string {
            print(titlesearch)
            let searchTerm = titlesearch.replacingOccurrences(of: "+", with: " ")
            let books = try Book.query().filter("title",searchTerm).all()
            
            return try JSON(node:books.makeNode())
        }
        if let isbn = request.data["isbn"]?.string{
            let books = try Book.query().filter("isbn", isbn).all()
            return try JSON(node: books.makeNode())
        }
        return try JSON(node: [])
    }
    
    
    
    
    
    
}
// MARK: - Helper Functions
extension  APIController {
    func findBooks(userId: Int, within distance:Double, from myLat:Double, longitude myLong:Double, completion:([Book])->()){
        
        let radiusOfEarth = 6371.0
        let angularRadius = distance/radiusOfEarth
        print(myLat)
        print(myLong)
        //        let lat = 0.0
        //        let long = 0.0
        let minLat = myLat - angularRadius
        let maxLat = myLat + angularRadius
        
        let maxT = asin(sin(myLat)/cos(angularRadius))
        
        let deltalon = acos((cos(angularRadius)-sin(maxT)*sin(myLat))/(cos(maxT)*cos(myLat)))
        let minLong = myLong - deltalon
        let maxLong = myLong + deltalon
        
        
        do {
            // this hits an error when empty double check and write tests
            let books = try Book.query()
                .filter("mainuser_id", Filter.Comparison.notEquals, userId)
                .filter("lat", Filter.Comparison.greaterThan, minLat)
                .filter("lat", Filter.Comparison.lessThan, maxLat)
                .filter("long", Filter.Comparison.greaterThan, minLong)
                .filter("long", Filter.Comparison.lessThan, maxLong)
                .all()
            
            print(books)
            
            var nearBooks = [Book]()
            for book in books {
                let booklat = book.lat
                let booklong = book.long
                print(acos(sin(myLat) * sin(booklat) + cos(myLat) * cos(booklat) * cos(booklong - (myLong))))
                print(angularRadius)
                
                let deltaCheck = acos(sin(myLat) * sin(booklat) + cos(myLat) * cos(booklat) * cos(booklong - (myLong))) <= angularRadius
                if deltaCheck{
                    print("hooray in range")
                    nearBooks.append(book)
                }else{
                    print("nah too far")
                }
            }
            
            completion(nearBooks)
        }catch{
            print("error")
        }
        
        
    }
}
