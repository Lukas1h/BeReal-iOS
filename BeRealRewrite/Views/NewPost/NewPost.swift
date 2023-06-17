//
//  NewPost.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/10/23.
//

import SwiftUI


struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
            )
            .foregroundColor(.primary)
            .font(.body)
    }
}

struct NewPost: View {
    @EnvironmentObject private var model: Model
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var captionText = ""
    @State private var isShowingAlert = false
    
    
    @Environment(\.dismiss) var dismiss
    
    func postImage(){
        Task.init{
            do {
                try await model.uploadPost(primaryUIImage: frontImage!, secondaryUIImage: backImage!,caption: captionText)
                try await model.fetchFriendPosts()
            } catch {
                print("error uploading post!")
                model.uploadingStatus = .failed
                model.uploadingFailedReason = error.localizedDescription.debugDescription
            }
            if(model.uploadingStatus == .failed){
                isShowingAlert = true
            }else{
                dismiss()
            }
        }
    }

    
    var body: some View {
        GeometryReader{ geo in
            if(model.uploadingStatus == .none || model.uploadingStatus == .failed){
                ZStack(alignment: .center){
                    if(frontImage != nil && backImage != nil){
                        VStack{
                            ZStack(alignment: .topLeading){
                                Image(uiImage:frontImage!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                Image(uiImage:backImage!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geo.size.width*0.35)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(.black, lineWidth: 3)
                                    )
                            }
                            .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .center)
                            .padding(4)
                            TextField("Caption",text:$captionText)
                                .textFieldStyle(CustomTextFieldStyle())
                                .padding([.horizontal,.bottom])
                            HStack{
                                Button{
                                    frontImage = nil
                                    backImage = nil
                                } label: {
                                    Text("Retake")
                                }
                                .buttonStyle(.bordered)
                                Spacer()
                                Button{
                                    postImage()
                                } label: {
                                    Text("Post")
                                }
                                .buttonStyle(.bordered)
                            }.padding([.horizontal,.bottom])
                        }
                        
                    }else {
                        CustomCameraView(frontImage: self.$frontImage, backImage: self.$backImage)
                    }
                }
            }else{
                ProgressView("Uploading Post")
                    .controlSize(.large)
                    .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .center)
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Failed"), message: Text(model.uploadingFailedReason ?? "Unknown Error"),  primaryButton: .default(Text("Try agian")) {
                model.uploadingStatus = .none
                dismiss()
            },
            secondaryButton: .default(Text("Okay")) {
                isShowingAlert = false
                dismiss()
            }
            )
        }
        .interactiveDismissDisabled()
    }
}




