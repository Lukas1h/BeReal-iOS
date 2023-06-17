//
//  Modal.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/3/23.
//  

import Foundation
import CoreData
import SwiftUI
#if targetEnvironment(simulator)
  // your simulator code
#else
  import WebP
#endif


enum FriendRequestType: String {
    case sent,received
}

struct FriendRequest: Codable, Identifiable {
    let id: String
    let username: String
    let fullname: String
    let status: String
//    let mutualFriends: Int
    let profilePicture: ProfilePicture?
}

struct ProfilePicture: Codable {
    let url: String
    let width: Int
    let height: Int
}

struct FriendRequestsResponse: Codable {
    let data: [FriendRequest]
}

struct User: Codable {
    init(id:String, username: String, fullname: String?) {
        self.id = id
        self.username = username
        self.fullname = fullname
    }
    
    let id: String
    let username: String
    let fullname: String?
}

struct DiscoveryFeed: Codable {
    let posts: [Post]
    let lastIndex: String
}

struct CommentRequest: Codable {
    let data: [Post.Comment]
}

struct Post: Codable,Identifiable {
    let id: String
    let userName: String
    let user: User
    let photoURL: String
    let secondaryPhotoURL: String
    
    
    let caption: String?
    let retakeCounter: Int
    let creationDate: CreationDate
    let takenAt: TakenAt
    let comment: [Comment]?
    
    

    struct Comment: Codable,Hashable,Identifiable {
        init(id: String,user:User,text:String) {
            self.id = id
            self.user = user
            self.text = text
            self.content = nil
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        static func == (lhs: Post.Comment, rhs: Post.Comment) -> Bool {
            return lhs.id == rhs.id
        }
        
        let id: String
        let text: String?
        let content: String?
        
        var commentText: String {
            if(text != nil){
                return text!
            }else if(content != nil){
                return content!
            }else {
                return "Umm, What?"
            }
            
        }
        
        let user: User
    }
    

    struct CreationDate: Codable {
        let _seconds: Int
        let _nanoseconds: Int
    }

    struct TakenAt: Codable {
        let _seconds: Int
        let _nanoseconds: Int
    }
}

struct AuthTokens {
    var refreshToken: String? = nil
    var accessToken: String? = nil
    var firebaseToken: String? = nil
    var expiresIn: Int16 = 3600
    var date: Date? = nil
    

}

enum UploadingStatus{
    case none
    case failed
    case started
    case compressingImages
    case parsingJson
    case gettingUploadUrl
    case uploadingImages
    case finalizing
    case done
    
}

struct Moment: Codable {
    let startDate: Date
    let id: String
}


class Model: ObservableObject {
    @Published var user: User?
    @Published var posts: [Post] = []
    @Published var authTokens = AuthTokens()
    @Published var isModalPresented: Bool = false
    @Published var modalView: AnyView = AnyView(Text("Loading..."))
    
    @Published var uploadingStatus: UploadingStatus = .none
    @Published var uploadingFailedReason: String? = nil
    
    @Published var deeplinkUrl: URL? = nil
    
    var moment: Moment? = nil
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    
    
    var isLoggedIn: Bool {
        authTokens.accessToken != nil && authTokens.refreshToken != nil && authTokens.firebaseToken != nil && user != nil
    }
    
    let service: Service
    let coreDataService: CoreDataService
    
    init(service: Service,coreDataService:CoreDataService) {
        self.service = service
        self.coreDataService = coreDataService
    }
    
    
    func onDeepLink(url:URL){
        if(isLoggedIn){
            
            print("Deeplinked from",url)
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                print("Invalid URL")
                return
            }
            
            guard let action = components.host else {
                print("Unknown URL, we can't handle this one!")
                return
            }
            
            if(action == "post"){
                print("Post is action!")
                guard let username = components.queryItems?.first(where: { $0.name == "username" })?.value else {
                    return
                }
                
                print("Username is ",username)
                
                
                guard let post = self.posts.first(where: {$0.userName == username}) else {
                    return
                }
                
    
                self.modalView = AnyView(FeedItem(post: post))
                self.isModalPresented = true
                print("feeditem is ",post)
                
                
            }


        }else{
            deeplinkUrl = url
        }
    }
    
    
    func logOut() throws{
        DispatchQueue.main.async {
            do {
                self.isModalPresented = false
                self.modalView = AnyView(Text("Loading..."))
                try self.coreDataService.clearTokens()
                self.authTokens = AuthTokens()
                self.posts = []
            } catch {
                print("error",error)
            }
        }
    }
    
    func deletePost(post:Post) throws {
        Task.init{
            try await self.service.deletePost(authTokens:authTokens,post:post)
        }
    }
    
    
    func uploadPost(primaryUIImage:UIImage,secondaryUIImage:UIImage,caption: String = "") async throws {
        uploadingStatus = .started
        try await self.service.uploadPost(authTokens: self.authTokens, primaryUIImage: primaryUIImage, secondaryUIImage: secondaryUIImage,caption: caption, uploadingStatus: &uploadingStatus)
        
    }
    
    func clearTokens() throws {
        try self.coreDataService.clearTokens()
    }
    
    func saveTokens() throws{
        try self.coreDataService.saveTokens(authTokens: self.authTokens)
        print("Will Save Tokens!")
        
        
        
    }
    

    func addComment(post:Post,commentText:String) async throws {
        print("model.addComment")
        try await self.service.addComment(post:post,text:commentText,authTokens: self.authTokens,user: self.user!)
    }
    
    
    func login(refreshToken: String? = nil) async throws {
        let oldRefreshToken: String
        
        if refreshToken == nil {
            let storedRefreshToken = try self.coreDataService.loadTokens().refreshToken
            if storedRefreshToken == nil{
                throw "login: Nil stored refresh token"
            }else{
                oldRefreshToken = storedRefreshToken!
            }
        }else{
            oldRefreshToken = refreshToken!
        }
        
        
        
        let (newAccessToken,newRefreshToken) = try await self.service.getAccessTokenAndNewRefreshToken(refreshToken: oldRefreshToken)
        let newFirebaseToken = try await self.service.getFirebaseToken(accessToken: newAccessToken)
        let user = try await self.service.fetchSelf(firebaseToken: newFirebaseToken)
        
        let newAuthTokens = AuthTokens(refreshToken: newRefreshToken,accessToken: newAccessToken,firebaseToken: newFirebaseToken,date: Date())
        try self.coreDataService.saveTokens(authTokens: newAuthTokens)
        
        if let userDefaults = UserDefaults(suiteName: "group.SPRCP3KG5X.com.ftL.bereal") {
            print("Saved UserDefaults!")
            userDefaults.set(newAuthTokens.refreshToken, forKey: "refreshToken")
            userDefaults.set(newAuthTokens.accessToken, forKey: "accessToken")
        }else{
            print("ERROR GETTING USER DEFAULTS!")
        }
        
        if let userDefaults = UserDefaults(suiteName: "group.SPRCP3KG5X.com.ftL.bereal") {
            print("GOT UserDefaults!")
            print(userDefaults.dictionaryRepresentation()["refreshToken"])
        }else{
            print("ERROR GETTING USER DEFAULTS!")
        }
        
        
        
        self.moment = try await self.service.getMoment()
        
        let timeLeft = Int(Date.now.distance(to: self.moment!.startDate))

        
        
        
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
//            if success {
//                let content = UNMutableNotificationContent()
//                content.title = "\(timeLeft<0 ? "Test: " : "")BeReal Time!"
//                content.subtitle = "Time to take your BeReal and share it with your friends!"
//                content.sound = UNNotificationSound.default
//
//                // show this notification five seconds from now
//                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timeLeft<0 ? 10 : timeLeft), repeats: false)
//
//                // choose a random identifier
//                let request = UNNotificationRequest(identifier:self.moment!.id, content: content, trigger: trigger)
//
//                // add our notification request
//                UNUserNotificationCenter.current().add(request)
//                print("NOTFICATION  SECDULED FOR \(TimeInterval(timeLeft<0 ? 10 : timeLeft))")
//            } else if let error = error {
//                print(error.localizedDescription)
//            }
//        }
        
        
        
        DispatchQueue.main.async {
            self.authTokens = newAuthTokens
            self.user = user
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                if(self.deeplinkUrl != nil){
                    print("calling deeplink after login 3333")
                    self.onDeepLink(url: self.deeplinkUrl!)
                }
            }
            
        }
        
        
    
    }
    
    func fetchFriendPosts() async throws{
        let newPosts = try await self.service.fetchFriendPosts(authTokens: self.authTokens)
        print(newPosts)
        DispatchQueue.main.async {
            self.posts = newPosts
        }
    }
    func fetchPublicPosts() async throws{
        let newPosts = try await self.service.fetchPublicPosts(authTokens: self.authTokens)
        print(newPosts)
        DispatchQueue.main.async {
            self.posts = newPosts
        }
    }
    
    func getSentFriendRequests() async throws -> [FriendRequest]{
        return try await self.service.getFriendRequests(authTokens:self.authTokens,requestType:.sent)
    }
    
    func getReceivedFriendRequests() async throws -> [FriendRequest]{
        return try await self.service.getFriendRequests(authTokens:self.authTokens,requestType:.received)
    }
    func getFriends() async throws -> [FriendRequest]{
        return try await self.service.getFriends(authTokens:self.authTokens)
    }
}


class Service {
    #if targetEnvironment(simulator)
    // your simulator code
    #else
        let encoder = WebPEncoder()
    #endif
    
    func deletePost(authTokens:AuthTokens,post:Post) async throws{
        guard let token = authTokens.firebaseToken else {
            throw "uploadPost: nil Token"
        }
        
        let url = URL(string: "https://mobile.bereal.com/api/content/posts")!

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let jsonPayload = """
        {"data":{"uid":"\(post.id)"}}
        """
        print("Payload",jsonPayload)
        request.httpBody = jsonPayload.data(using: .utf8)
        request.addValue("Bearer "+token, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "content-type")

        let (data, response) =  try await URLSession.shared.data(for: request)

        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Failed to get `HTTPURLResponce` from `responce`."
        }
        
        if(httpResponse.statusCode>399 || httpResponse.statusCode<200){
            throw "fetchFriendPosts: Bad Status Code: \(httpResponse.statusCode)"
        }
        
        print("deleted post",String(data: data, encoding: .utf8))
        
    }
    
    #if targetEnvironment(simulator)
    
    func uploadPost(authTokens:AuthTokens,primaryUIImage:UIImage,secondaryUIImage:UIImage,caption: String = "", uploadingStatus: inout UploadingStatus) async throws {
        throw "No Simulator Method"
    }
    
    #else
    
    func uploadPost(authTokens:AuthTokens,primaryUIImage:UIImage,secondaryUIImage:UIImage,caption: String = "", uploadingStatus: inout UploadingStatus) async throws {
        guard let token = authTokens.firebaseToken else {
            throw "uploadPost: nil Token"
        }
        
        uploadingStatus = .compressingImages
        
        let frontImageData = try encoder.encode(primaryUIImage, config: .preset(.picture, quality: 95))
        let backImageData = try encoder.encode(secondaryUIImage, config: .preset(.picture, quality: 95))
        
        uploadingStatus = .gettingUploadUrl
        
        let url = URL(string: "https://mobile.bereal.com/api/content/posts/upload-url?mimeType=image/webp")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer "+token, forHTTPHeaderField: "authorization")
        
        let (data, response) =  try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Failed to get `HTTPURLResponce` from `responce`."
        }
        
        if(httpResponse.statusCode>399 || httpResponse.statusCode<200){
            throw "fetchFriendPosts: Bad Status Code: \(httpResponse.statusCode)"
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        print("Got json!",json)
        
        if((json!["data"] as? NSArray ) == nil){
            throw "Failed to get json"
        }
        
        let primaryUploadURL = ((json!["data"] as? NSArray )![1] as? [String: Any] )!["url"] as! String
        let primaryUploadPath = ((json!["data"] as? NSArray )![1] as? [String: Any] )!["path"] as! String
        let secondaryUploadURL = ((json!["data"] as? NSArray )![0] as? [String: Any] )!["url"] as! String
        let secondaryUploadPath = ((json!["data"] as? NSArray )![0] as? [String: Any] )!["path"] as! String
        
        
        print("primaryUploadURL",primaryUploadURL)
        print("primaryUploadPath",primaryUploadPath)
        print("secondaryUploadURL",secondaryUploadURL)
        print("secondaryUploadPath",secondaryUploadPath)
        
        
        var primaryUploadRequest = URLRequest(url: URL(string: primaryUploadURL)!)
        primaryUploadRequest.httpMethod = "PUT"
        primaryUploadRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        primaryUploadRequest.setValue("1024,1048576", forHTTPHeaderField: "x-goog-content-length-range")
        primaryUploadRequest.setValue("image/webp", forHTTPHeaderField: "Content-Type")
        primaryUploadRequest.setValue("public,max-age=172800", forHTTPHeaderField: "Cache-Control")
        primaryUploadRequest.setValue("keep-alive", forHTTPHeaderField: "Connection")


        let (primaryUploadRequestData, primaryUploadRequestResponse) = try await URLSession.shared.upload(for: primaryUploadRequest, from: frontImageData)
        
        print("Uploaded one")
        print("Body" ,String(data: primaryUploadRequestData, encoding: .utf8) as Any)
        
        
        
        var secondaryUploadRequest = URLRequest(url: URL(string: secondaryUploadURL)!)
        secondaryUploadRequest.httpMethod = "PUT"
        secondaryUploadRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        secondaryUploadRequest.setValue("1024,1048576", forHTTPHeaderField: "x-goog-content-length-range")
        secondaryUploadRequest.setValue("image/webp", forHTTPHeaderField: "Content-Type")
        secondaryUploadRequest.setValue("public,max-age=172800", forHTTPHeaderField: "Cache-Control")
        secondaryUploadRequest.setValue("keep-alive", forHTTPHeaderField: "Connection")


        let (secondaryUploadRequestData, secondaryUploadRequestResponse) = try await URLSession.shared.upload(for: secondaryUploadRequest, from: backImageData)
        
        print("Uploaded two")
        print("Body" ,String(data: secondaryUploadRequestData, encoding: .utf8) as Any)
        
        
        
        let finalizeURL = URL(string: "https://mobile.bereal.com/api/content/posts")!

        var finalizeRequest = URLRequest(url: finalizeURL)
        finalizeRequest.httpMethod = "POST"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
        let dateString = dateFormatter.string(from: Date())
        
        let parameters = """
        {
            "visibility": ["friends"],
            "isLate": false,
            "retakeCounter": 0,
            "takenAt": "\(dateString)",
            "backCamera": {
                "bucket": "storage.bere.al",
                "height": 1500,
                "width": 2000,
                "path": "\(secondaryUploadPath)"
            },
            "frontCamera": {
                "bucket": "storage.bere.al",
                "height": 1500,
                "width": 2000,
                "path": "\(primaryUploadPath)"
            },
            "caption": "\(caption)"
        }
        """
        
        print(parameters)
        finalizeRequest.httpBody = parameters.data(using: .utf8)

        finalizeRequest.addValue("Bearer "+token, forHTTPHeaderField: "authorization")
        finalizeRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (finalizeRequestData, finalizeRequestResponse) =  try await URLSession.shared.data(for: finalizeRequest)
        
        guard let finalizeRequestHttpResponse = finalizeRequestResponse as? HTTPURLResponse else {
            throw "Failed to get `HTTPURLResponce` from `responce`."
        }
        
        print("code ",finalizeRequestHttpResponse.statusCode)
        if(finalizeRequestHttpResponse.statusCode>399 || finalizeRequestHttpResponse.statusCode<200){
            print("trowing error for status cdoe")
            throw "\(finalizeRequestHttpResponse.statusCode) Error. \(String(data: finalizeRequestData, encoding: .utf8)!)"
        }
        
        print(String(data: finalizeRequestData, encoding: .utf8)!)
        

        
    }
    
    #endif
    
    func acceptFriendRequest(authTokens: AuthTokens) async throws {
        guard let token = authTokens.firebaseToken else {
            throw "acceptFriendRequest: nil Token"
        }
        if(token.isEmpty){
            throw "acceptFriendRequest: empty Token"
        }
    }
    
    func getMoment() async throws -> Moment {
        print("Getting moment")
        
        let url = URL(string: "https://mobile.bereal.com/api/bereal/moments/last/us-central")!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        print("Got data \(String(data: data, encoding: .utf8) ?? "")")
        
        let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        
        guard let startDateString = dict?["startDate"] as? String else {
            print("Error getting moment start date string")
            throw "Error getting moment"
        }
        
        guard let id = dict?["id"] as? String else {
            print("Error getting moment id")
            throw "Error getting moment"
        }
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let startDate = dateFormatter.date(from: startDateString) else {
            print("Error getting moment start date")
            throw "Error getting moment"
        }
        
        
        let calendar = Calendar.current
        let secondsToRemove = 25080 //7 hours
        var dateComponents = DateComponents()
        dateComponents.second = -secondsToRemove
        let subdStartDate = calendar.date(byAdding: dateComponents, to: startDate)!

        
        
        return Moment(startDate: subdStartDate,id: id)
        
    }
    
    
    func getFriendRequests(authTokens:AuthTokens,requestType:FriendRequestType) async throws -> [FriendRequest]{
        print("service.getSentFriendRequests")
        guard let token = authTokens.firebaseToken else {
            throw "getSentFriendRequests: nil Token"
        }
        if(token.isEmpty){
            throw "getSentFriendRequests: empty Token"
        }

        let url = URL(string: "https://mobile.bereal.com/api/relationships/friend-requests/\(requestType.rawValue)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer "+token, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        
        let (data, response) =  try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Failed to get `HTTPURLResponce` from `responce`."
        }
        
        if(httpResponse.statusCode>399 || httpResponse.statusCode<200){
            throw "fetchFriendPosts: Bad Status Code: \(httpResponse.statusCode)"
        }
        
        
        let decoder = JSONDecoder()
        let friendRequestResponce = try decoder.decode(FriendRequestsResponse.self, from: data)
        print("got data",String(data: data, encoding: .utf8))
        print("got json", friendRequestResponce.data)
        return friendRequestResponce.data
    }
    
    func getFriends(authTokens:AuthTokens) async throws -> [FriendRequest]{
        print("service.getSentFriendRequests")
        guard let token = authTokens.firebaseToken else {
            throw "getSentFriendRequests: nil Token"
        }
        if(token.isEmpty){
            throw "getSentFriendRequests: empty Token"
        }

        let url = URL(string: "https://mobile.bereal.com/api/relationships/friends")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer "+token, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        
        let (data, response) =  try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Failed to get `HTTPURLResponce` from `responce`."
        }
        
        if(httpResponse.statusCode>399 || httpResponse.statusCode<200){
            throw "fetchFriendPosts: Bad Status Code: \(httpResponse.statusCode)"
        }
        
        
        let decoder = JSONDecoder()
        let friendRequestResponce = try decoder.decode(FriendRequestsResponse.self, from: data)
        print("got data",String(data: data, encoding: .utf8))
        print("got json", friendRequestResponce.data)
        return friendRequestResponce.data
    }
    
    func getComment(post:Post,text:String,authTokens:AuthTokens,user:User) async throws -> [Post.Comment]{
        print("service.addComment")
        guard let token = authTokens.firebaseToken else {
            throw "fetchFriendPosts: nil Token"
        }
        if(token.isEmpty){
            throw "fetchFriendPosts: empty Token"
        }

        let postUrlString = "https://mobile.bereal.com/api/content/comments?postId=\(post.id)&postUserId=\(post.user.id)"
        guard let postUrl = URL(string: postUrlString) else {
            // Handle invalid URL
            throw "Opps"
        }
        
        var request = URLRequest(url: postUrl)
        request.httpMethod = "GET"
        request.addValue("Bearer "+token, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        
        let (data, response) =  try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Failed to get `HTTPURLResponce` from `responce`."
        }
        
        if(httpResponse.statusCode>399 || httpResponse.statusCode<200){
            throw "fetchFriendPosts: Bad Status Code: \(httpResponse.statusCode)"
        }
        
        
        let decoder = JSONDecoder()
        let comments = try decoder.decode(CommentRequest.self, from: data)
        return comments.data
    }
    
    
    func addComment(post:Post,text:String,authTokens:AuthTokens,user:User) async throws{
        print("service.addComment")
        guard let token = authTokens.firebaseToken else {
            throw "fetchFriendPosts: nil Token"
        }
        if(token.isEmpty){
            throw "fetchFriendPosts: empty Token"
        }

        let postUrlString = "https://mobile.bereal.com/api/content/comments?postId=\(post.id)&postUserId=\(post.user.id)"
        guard let postUrl = URL(string: postUrlString) else {
            // Handle invalid URL
            return
        }
        
        // Construct the request object
        var postRequest = URLRequest(url: postUrl)
        postRequest.httpMethod = "POST"
        
        // Construct the request body JSON
        print("oyoyoyoyo", postUrlString)
        print("{\"content\":\"\(text)\"}")
        
        
        let bodyString = """
    {"content":"\(text)"}
    """
        postRequest.httpBody = bodyString.data(using: .utf8)
        
        // Add any required headers (e.g. authentication)
        postRequest.addValue("Bearer "+token, forHTTPHeaderField: "Authorization")
        postRequest.addValue("application/json", forHTTPHeaderField: "content-type")
        
        // Create the session and data task
        let session = URLSession.shared
        let task = try await session.data(for: postRequest)
        
//        task.resume()
    }
    
    func fetchPublicPosts(authTokens: AuthTokens) async throws -> [Post] {
        
        guard let token = authTokens.firebaseToken else {
            throw "fetchFriendPosts: nil Token"
        }
        if(token.isEmpty){
            throw "fetchFriendPosts: empty Token"
        }

        
        let url = URL(string: "https://mobile.bereal.com/api/feeds/discovery?limit=10")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.addValue("Bearer "+token, forHTTPHeaderField: "authorization")
        
        print("Fetching Posts")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("Done fetching")
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Failed to get `HTTPURLResponce` from `responce`."
        }
        
        if(httpResponse.statusCode>399 || httpResponse.statusCode<200){
            throw "fetchFriendPosts: Bad Status Code: \(httpResponse.statusCode)"
        }
        
        
        let decoder = JSONDecoder()
        let posts = try decoder.decode(DiscoveryFeed.self, from: data)
        return posts.posts
        
    }
    
    
    
    func fetchFriendPosts(authTokens: AuthTokens) async throws -> [Post] {
        
        guard let token = authTokens.firebaseToken else {
            throw "fetchFriendPosts: nil Token"
        }
        if(token.isEmpty){
            throw "fetchFriendPosts: empty Token"
        }

        
        let url = URL(string: "https://mobile.bereal.com/api/feeds/friends")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.addValue("Bearer "+token, forHTTPHeaderField: "authorization")
        
        print("Fetching Posts")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("Done fetching")
        print(String(data: data, encoding: .utf8))
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Failed to get `HTTPURLResponce` from `responce`."
        }
        
        if(httpResponse.statusCode == 502){
            print("502, tring agian")
            return try await self.fetchFriendPosts(authTokens: authTokens)
        }
        
        if(httpResponse.statusCode>399 || httpResponse.statusCode<200){
            throw "fetchFriendPosts: Bad Status Code: \(httpResponse.statusCode)"
        }
        
        
        let decoder = JSONDecoder()
        let posts = try decoder.decode([Post].self, from: data)
        return posts
        
    }
    
    func getAccessTokenAndNewRefreshToken(refreshToken: String) async throws -> (String,String) {
        
        if(refreshToken == ""){
           throw "Found `nil` while getting refreshToken. Is the user logged it?"
        }
        

        print("Getting new tokens with refresh token",refreshToken)
        
        
        let url = URL(string: "https://securetoken.googleapis.com/v1/token?key=AIzaSyDwjfEeparokD7sXPVQli9NsTuhT6fJ6iA")!
        
        let body = """
        {
            "grant_type": "refresh_token",
            "refresh_token": "\(refreshToken)"
        }
        """
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)
        
        print("Fetching first")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]

        guard let accessToken = json?["access_token"] as? String else {
            throw "Found empty accessToken from request"
        }
        
        guard let refreshToken = json?["refresh_token"] as? String else {
            throw "Found empty accessToken from request"
        }
            
        return (accessToken,refreshToken)
    }
    
    func getFirebaseToken(accessToken: String) async throws -> String {
        
        
        if(accessToken.isEmpty){
           throw "getFirebaseToken: Found emptry while getting accessToken."
        }
        

        
        
        let url = URL(string: "https://auth.bereal.team/token?grant_type=firebase")!
        
        let body = """
        {
            "grant_type": "firebase",
            "client_id":"android",
            "client_secret": "F5A71DA-32C7-425C-A3E3-375B4DACA406",
            "token": "\(accessToken)"
        }
        """
        
        print("Body",body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)

        print("Fetching second")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (httpResponse.statusCode > 200 && httpResponse.statusCode < 400)  else {
            print("Bad status code ",String(data: data, encoding: .utf8))
            throw URLError(.badServerResponse)
        }
        print("Date",String(data: data, encoding: .utf8))
        
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]

        guard let firebaseToken = json?["access_token"] as? String else {
            throw "Found empty accessToken from request"
        }
        

        return firebaseToken
    }
    
    
    
    func fetchSelf(firebaseToken: String) async throws -> User {
        
        if(firebaseToken == ""){
            throw "Could'nt find firebaeToken."
        }
        
        let url = URL(string: "https://mobile.bereal.com/api/person/me")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        print("Bearer "+firebaseToken)
        request.setValue("Bearer "+firebaseToken, forHTTPHeaderField: "Authorization")
        
        print("Fetching User")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("Done fetching")
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Failed to get `HTTPURLResponce` from `responce`."
        }
        
        if(httpResponse.statusCode>399 || httpResponse.statusCode<200){
            throw "Bad Status Code: \(httpResponse.statusCode)"
        }
        
        
        let decoder = JSONDecoder()
        print("MEEEEEEEE:",String(data: data, encoding: .utf8)!)
        let user = try decoder.decode(User.self, from: data)
        return user

    }
}

class CoreDataService {
    let container: NSPersistentContainer
    
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Model")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }else{
                print("Loaded `container`")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func clearTokens() throws{
        print("Clearing tokens")
        
        let context = container.viewContext
        let request = NSFetchRequest<CDAuthToken>(entityName: "CDAuthToken")
        let fetchRequest = try context.fetch(request)
        
        guard let newTokens = fetchRequest.first else {
            return
        }
        
        context.delete(newTokens)
        
        try context.save()
        
    }
    
    func loadTokens() throws -> AuthTokens{
        
        let context = container.viewContext
        let request = NSFetchRequest<CDAuthToken>(entityName: "CDAuthToken")
        
        let tokens: CDAuthToken
        
        let fetchRequest = try context.fetch(request)
        print("Recievd Fetch Request")
        
        if let newTokens = fetchRequest.first {
            tokens = newTokens
            print("Previous tokens found :")
            print(tokens)
        }else{
            tokens = CDAuthToken(context: context)
            print("No previous tokens found. Creating new one.")
        }
        print("Returning New Tokens")
        return AuthTokens(refreshToken: tokens.refreshToken ,accessToken: tokens.accessToken,firebaseToken: tokens.firebaseToken,expiresIn: tokens.expiresIn, date: tokens.date)
    }
    
    func saveTokens(authTokens:AuthTokens) throws{
        let accessToken = authTokens.accessToken
        let refreshToken = authTokens.refreshToken
        let firebaseToken = authTokens.firebaseToken
        let date = authTokens.date
        
        print("== Saving Tokens",accessToken,refreshToken,firebaseToken)
        
        let context = container.viewContext
        let request = NSFetchRequest<CDAuthToken>(entityName: "CDAuthToken")
        print("Saving Tokens.")
        
        let tokens: CDAuthToken
        print("Going To Make Fetch Requesr.")
        print("request is ",request)
        print("context is ",context)
        
        let fetchRequest = try context.fetch(request)
        
        
        print("Made Fetch Request.")
        
        if let newTokens = fetchRequest.first {
            tokens = newTokens
            print("Previous tokens found.")
        }else{
            tokens = CDAuthToken(context: context)
            print("No previous tokens found. Creating new one.")
        }
        
        
        if(firebaseToken != nil){
            print("Setting `firebaseToken` to \(firebaseToken!)")
            tokens.date = date
            tokens.firebaseToken = firebaseToken!
        }
        if(refreshToken != nil){
            print("Setting `refreshToken` to \(refreshToken!)")
            tokens.date = date
            tokens.refreshToken = refreshToken!
        }
        if(accessToken != nil){
            print("Setting `accessToken` to \(accessToken!)")
            tokens.date = Date()
            tokens.accessToken = accessToken!
        }
        try context.save()
        
        

    }
    
    
}







extension String: Error {}


extension Task where Failure == Never, Success == Void {
    init(priority: TaskPriority? = nil, operation: @escaping () async throws -> Void, `catch`: @escaping (Error) -> Void) {
        self.init(priority: priority) {
            do {
                _ = try await operation()
            } catch {
                `catch`(error)
            }
        }
    }
}
