//
//  Widget.swift
//  Widget
//
//  Created by Lukas Hahn on 6/12/23.
//

import WidgetKit
import SwiftUI
import Intents


func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data, error == nil else {
            completion(nil)
            return
        }
        
        let image = UIImage(data: data)
        completion(image)
    }.resume()
}



struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> BeRealEntry {
        print("Get Placeholder")
        
        return BeRealEntry(date: Date(),data: BeRealItem(user: "", frontImage: nil,isLoading: true))
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (BeRealEntry) -> ()) {
        print("Get Snap")
        
        let entry = BeRealEntry(date: Date(),data: BeRealItem(user: "Loading...", frontImage: nil,isLoading: true))
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let service = Service()
        
        if let userDefaults = UserDefaults(suiteName: "group.SPRCP3KG5X.com.ftL.bereal") {
            
            
            guard let refreshToken = userDefaults.string(forKey: "refreshToken") else {
                return
            }
            
            
            Task.init{
                do {
                    let (newAccessToken,newRefreshToken) = try await service.getAccessTokenAndNewRefreshToken(refreshToken:refreshToken)
                    let newFirebaseToken = try await service.getFirebaseToken(accessToken: newAccessToken)
                    
                    let authTokens = AuthTokens(refreshToken: newRefreshToken,accessToken: newAccessToken,firebaseToken: newFirebaseToken)
                    let posts = try await service.fetchFriendPosts(authTokens: authTokens)
                    
                    
                    var entries:[BeRealEntry] = []
                    
                    // Create a dispatch group to wait for all image downloads to complete
                    let downloadGroup = DispatchGroup()
                    
                    // Iterate over each post in the `posts` array
                    let currentDate = Date()
                    
                    for offset in 0 ..< posts.count {
                        let post = posts[offset]
                        downloadGroup.enter()


                        downloadImage(from: URL(string: post.secondaryPhotoURL)!) { image1 in
                            
                            let entryDate = Calendar.current.date(byAdding: .second, value: offset*10, to: currentDate)!
                            
                            let entry = BeRealEntry(date: entryDate, data: BeRealItem(user: post.userName, frontImage: image1?.resized(toWidth: 400),isLoading: false))
                            entries.append(entry)
                            downloadGroup.leave()
                            
                        }
                        
                    }

                    
                    // Notify when all image downloads are complete
                    downloadGroup.notify(queue: .main) {
                        let timeline = Timeline(entries: entries, policy: .atEnd)
                        completion(timeline)
                    }
                } catch {
                    print("Failed",error)
                }
            }
        }
    }
}

struct BeRealItem {
    let user: String
    let frontImage: UIImage?
    let isLoading: Bool
    
}

struct BeRealEntry: TimelineEntry {
    let date: Date
    let data: BeRealItem
}



struct WidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    @State private var createEventDic: NSMutableDictionary = [:]

    var body: some View {
        GeometryReader{geo in
            ZStack(alignment: .bottom){
                
                if(entry.data.isLoading){
                    Rectangle()
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                        
                }else{
                    if let frontImage = entry.data.frontImage {
                        Image(uiImage: frontImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width,height: geo.size.height)
                    }
                }
                
                HStack{
                    if(entry.data.isLoading){
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                            .frame(width:130,height: 18)
                            .padding(4)
                    }else{
                        Text("@"+entry.data.user)
                            .lineLimit(1)
                            .font(.system(size: widgetFamily == .systemSmall ? 16 : 18,weight: .bold,design: .rounded))
                            .shadow(radius: 8)
                            .padding(4)
                    }
                    Spacer()
                    if(widgetFamily != .systemSmall){
                        if(entry.data.isLoading){
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .frame(width:120,height: 18)
                        }else{
                        
                            Text("Add Comment")
                                .font(.system(size: 18,weight: .bold,design: .rounded))
                                .shadow(radius: 8)
                        }
                    }
                    
                }
                .padding(widgetFamily == .systemSmall ? 8 : 16)
            }
        }
        .foregroundColor(.white)
        .widgetURL(URL(string: "bereal://post?username=lukas__with__a__k")!)
    }
}

struct Widget: SwiftUI.Widget {
    let kind: String = "Widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Feed")
        .description("Show your friends recent posts.")
        .supportedFamilies([.systemSmall,.systemLarge])
    }
}

struct Widget_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            WidgetEntryView(entry: BeRealEntry(date: Date(),data: BeRealItem(user: "lukas_hahn" , frontImage: UIImage(named: "preview"), isLoading: true)))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            WidgetEntryView(entry: BeRealEntry(date: Date(),data: BeRealItem(user: "lukas_hahn" , frontImage: UIImage(named: "preview"), isLoading: false)))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}




extension UIImage {
  func resized(toWidth width: CGFloat, isOpaque: Bool = true) -> UIImage? {
    let canvas = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
    let format = imageRendererFormat
    format.opaque = isOpaque
    return UIGraphicsImageRenderer(size: canvas, format: format).image {
      _ in draw(in: CGRect(origin: .zero, size: canvas))
    }
  }
}
