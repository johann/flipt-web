import Vapor
import VaporPostgreSQL
import Auth
import HTTP
import Cookies
import Turnstile
import TurnstileCrypto
import TurnstileWeb
import Fluent
import Foundation



let auth = AuthMiddleware<MainUser>()

let database = Database(MemoryDriver())
let drop = Droplet()
drop.middleware += auth
drop.middleware += TrustProxyMiddleware()
drop.database = database
try drop.addProvider(VaporPostgreSQL.Provider.self)
drop.preparations += Book.self
drop.preparations += MainUser.self





let bookController = BookController()
bookController.addRoutes(drop: drop)
let userController = UserController()
userController.addRoutes(drop: drop)
let apiController = APIController()
apiController.addRoutes(drop: drop)






drop.get { request in
    
    let user = try? request.user()
    var dashboardView = try Node(node: [
        "authenticated": user != nil,
        ])
    dashboardView["account"] = try user?.makeNode()
    dashboardView["books"] = try user?.books().makeNode()
    
    return try drop.view.make("index", dashboardView)
}



drop.get("users"){ request in
    
    return try JSON(node:MainUser.all().makeNode())
    
}

drop.get("seedUsers") { request in
    var amelia = MainUser(firstName: "Amelia", lastName: "Theresa", username: "amg")
    var johann = MainUser(firstName: "Johann", lastName: "Kerr", username: "johannkerr")
    var joel = MainUser(firstName: "Joel", lastName: "Bell", username: "joelconnects")
    var jim = MainUser(firstName: "Jim", lastName: "Campagno", username: "jimhair")
    try amelia.save()
    try johann.save()
    try joel.save()
    try jim.save()

    
    var userArray = [amelia, johann, joel, jim]
    return try JSON(node:["success":userArray.makeNode()])
}

drop.get("seedBooks") { request in
    
//    
    
    let url = "https://www.googleapis.com/books/v1/volumes?q=subject:fiction&maxResults=40"
    let response = try drop.client.get(url)
    var petArray = [Book]()
    let next = response.data["data","after"]?.string ?? ""
    let linkArray = response.data["items", "volumeInfo"]?.array?.flatMap({$0.object}) ?? []
    
    var books = [Book]()
    for link in linkArray {
        let title = link["title"]?.string ?? ""
        let lat = 0.710689252157797
        let long = -1.29128316568814
        //figure out mainuser
        let publisher = link["publisher"]?.string ?? ""
        let publishYear = link["publishedDate"]?.string ?? ""
        let description = link["description"]?.string ?? ""
        let truncatedDescription = description.trunc(length: 245)
        let authorArray = link["authors"]?.array ?? []
        let author = authorArray.first?.string ?? ""
        let industryIdentifier = link["industryIdentifiers"]?.array ?? []
        let isbn13 = industryIdentifier.first?.object ?? [:]
        let isbnString = isbn13["identifier"]?.string ?? ""
        let imageLinks = link["imageLinks"]?.object ?? [:]
        let thumbnail = imageLinks["thumbnail"]?.string ?? ""
        let largeImage = thumbnail.replacingOccurrences(of: "&zoom=1", with: "")
        
        
        let mainuser_id = try MainUser.getRandomId()
        if let user_id = mainuser_id {
            var book = Book(title: title, isbn: isbnString, imgUrl: largeImage, lat: lat, long: long, mainuser_id: user_id, publisher: publisher, author: author, description: truncatedDescription, publishYear: publishYear)
            try book.save()
            books.append(book)
        }
        
        
    }
//
    
    return try JSON(node:["success":books.makeNode()])
    
    
    
    
}

drop.run()
