//
//  ContentView.swift
//  PhotosSearch
//
//  Created by Xipu Li on 5/16/24.
//

import SwiftUI

struct ContentView: View {
    @FocusState private var inputFocused: Bool
    @ObservedObject var photoSearcher = PhotoSearcher()
    @State var showBuildIndexView = false
    @State var searchText: String = ""
    
    
    private let showString: LocalizedStringKey = ["My love", "Dark night room with a lamp", "Snow outside the window", "Deep blue", "Cute kitten", "Photos of our gathering", "Beach, waves, sunset", "In car view, car on the road", "Screen display of traffic info", "Selfie in front of mirror", "Cheers"].randomElement()!
    
    var body: some View {
        
        if showBuildIndexView {
            BuildIndexView(photoSearcher: photoSearcher)
                .onAppear {
                    Task {
                        photoSearcher.buildIndexCode = .PHOTOS_LOADED
                        await photoSearcher.fetchPhotos()
                        photoSearcher.buildIndexCode = .PHOTOS_LOADED
                    }
                }
                .onDisappear {
                    photoSearcher.buildIndexCode = .DEFAULT
                }
            
        }
        
        else {
            
            VStack{
                
                switch photoSearcher.searchResultCode {
                case .DEFAULT:
                    ProgressView() {
                        Text("Loading Model...")
                    }
                    .onAppear {
                        Task {
                            await photoSearcher.prepareModelForSearch()
                            
                            //                             let hasAccessToPhotos = UserDefaults.standard.bool(forKey: photoSearcher.KEY_HAS_ACCESS_TO_PHOTOS)
                            //                             if hasAccessToPhotos == true {
                            //                                 // which means I have the access to Photo Library.
                            //                                 await photoSearcher.fetchPhotos()
                            //                             }
                        }
                    }
                case .MODEL_PREPARED:
                    Text("Model Prepared")
                case .NEVER_INDEXED:
                    FirstTimeSearchView(showBuildIndexView: $showBuildIndexView, photoSearcher: photoSearcher)
                    
                case .IS_SEARCHING:
                    ProgressView() {
                        Text("Searching...")
                            .accessibilityAddTraits(.isStaticText)
                            .accessibilityValue(Text("Searching"))
                    }
                    
                default:
                    Text("")
                }
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .accessibilityHidden(true)
                    TextField(showString, text: $searchText)
                        .multilineTextAlignment(.leading)
                        .focused($inputFocused)
                        .accessibilityAddTraits(.isSearchField)
                        .accessibilityHint(Text("Input your sentences here, then press enter"))
                        .onSubmit {
                            print("Searching...")
                            Task {
                                await photoSearcher.search(with: searchText)
                            }
                        }
                        .submitLabel(.search)
                    if !searchText.isEmpty {
                        Button {
                            self.clearSearch()
                        } label: {
                            Image(systemName: "delete.left")
                                .accessibilityLabel("Clear search")
                        }
                    }
                }.opacity(photoSearcher.searchResultCode == .DEFAULT || photoSearcher.searchResultCode == .NEVER_INDEXED ? 0 : 1)
            }}
        
    }
    
    private func clearSearch() {
        self.searchText = ""
        inputFocused = true
        photoSearcher.searchResultCode = .MODEL_PREPARED
    }
    
}

struct FirstTimeSearchView: View {
    @Binding public var showBuildIndexView: Bool
    @ObservedObject var photoSearcher: PhotoSearcher
    
    var body: some View {
        HStack (alignment: .center) {
            
            VStack {
                Spacer()
                Text("👋 Welcome!")
                    .font(.system(size: 50, weight: .black, design: .serif))
                    .padding(.bottom, 10)
                Spacer()
            }.padding(10)
            
            Divider()
           
            
            VStack (alignment: .leading) {
                
                Text("Get started by indexing photos of your choice.")
                    .padding(.bottom, 20)
                
                
                Group {
                    HStack {
                        Label("Queryable is an offline application. It runs smoothly without a network.", systemImage: "wifi.slash")
                    }.padding(.bottom, 8)
                    
                    HStack {
                        Label("The task is performed only once. It could take a few minutes, as it will index all your photos.", systemImage: "timer")
                    }.padding(.bottom, 8)
                    
                    HStack {
                        Label("You may need to manually update the index when you have new photos.", systemImage: "arrow.clockwise")
                    }
                }
                
              
                    Button("Get Started") {
                        showBuildIndexView = true
                    }
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.extraLarge)
             
               
                
            }.padding(30)
            
            
        }
        .padding()
        .frame(maxWidth: 800)
        
    

    }
}



//
//#Preview {
//    ContentView()
//
//}
