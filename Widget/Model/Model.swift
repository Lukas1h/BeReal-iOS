//
//  Model.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 6/13/23.
//

import Foundation

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



class Service {

    
    
    
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

