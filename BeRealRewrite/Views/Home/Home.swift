//
//  Home.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/4/23.
//

import SwiftUI

let text = "00"
let font = Font.system(size: 28, weight: .bold, design: .rounded)

let attributes: [NSAttributedString.Key: Any] = [
    .font: UIFont.systemFont(ofSize: 28, weight: .bold)
]

let timerTextWidth = (text as NSString).boundingRect(
    with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
    options: .usesLineFragmentOrigin,
    attributes: attributes,
    context: nil
).size.width



struct Home: View {
    @EnvironmentObject private var model: Model
    
    @State private var hour = 0
    @State private var min = 0
    @State private var sec = 0
    @State private var isPast = false
    
    var body: some View {
        NavigationView{
            ZStack(alignment: .top){
                HStack{
                    Menu {
                        Button {
                            print("Friends")
                            model.modalView = AnyView(FriendRequestsView())
                            model.isModalPresented = true
                        } label: {
                            Label("Friend Requests", systemImage: "person.fill")
                        }
                        Button {
                            model.modalView = AnyView(SettingsView())
                            model.isModalPresented = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(Font.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width:50,height: 50,alignment: .center)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10,style: .continuous))
                    .zIndex(1000)
                    
                    Spacer()
                    VStack(spacing:0){
                        if(!isPast){
                            Text("In")
                                .font(.system(size: 14,weight: .semibold,design: .rounded))
                                .padding(0)
                        }
                        HStack(spacing:0){
                            if(hour > 0){
                                Text("\(hour < 10 ? "0" : "")\(hour)")
                                    .id(hour)
                                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .scale), removal: .move(edge: .bottom).combined(with: .scale)).combined(with: .opacity))
                                    .frame(width:timerTextWidth)
                                Text(":")
                            }
                            if(min > 0 || hour > 0){
                                Text("\(min < 10 ? "0" : "")\(min)")
                                    .id(min)
                                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .scale), removal: .move(edge: .bottom).combined(with: .scale)).combined(with: .opacity))
                                    .frame(width:timerTextWidth)
                                Text(":")
                            }
                            if(true){ // i like consitency
                                Text("\(sec < 10 ? "0" : "")\(sec)")
                                    .id(sec)
                                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .scale), removal: .move(edge: .bottom).combined(with: .scale)).combined(with: .opacity))
                                    .frame(width:timerTextWidth)
                            }
                        }
                        .font(.system(size: 28,weight: .bold,design: .rounded))
                        .shadow(radius: 10)
                        .onReceive(model.timer){ _ in
                            withAnimation(.spring()){
                                if let startDate = model.moment?.startDate{
                                    let left = Int(Date.now.distance(to: startDate))
                                    isPast = left < 0
                                    let (hourn,minn,secn) = secondsToHoursMinutesSeconds(abs(left))
                                    hour = hourn
                                    min = minn
                                    sec = secn
                                }else{
                                    hour = 0
                                    min = 0
                                    sec = 0
                                }
                            }
                        }
                        if(isPast){
                            Text("Ago")
                                .font(.system(size: 14,weight: .semibold,design: .rounded))
                                .padding(0)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        model.modalView = AnyView(NewPost())
                        model.isModalPresented = true
                    } label: {
                        Image(systemName: "plus.square")
                            .font(Font.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .frame(width:50,height: 50,alignment: .center)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10,style: .continuous))
                    .zIndex(1000)
                }
                .zIndex(10000)
                .edgesIgnoringSafeArea(.all)
                .padding()
                Feed()
                    .edgesIgnoringSafeArea(.all)
                    .navigationBarHidden(true)
            }
        }
    }
}

func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
