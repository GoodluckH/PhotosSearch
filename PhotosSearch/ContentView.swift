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
    
      @State var searchText: String = ""
      private let showString: LocalizedStringKey = ["My love", "Dark night room with a lamp", "Snow outside the window", "Deep blue", "Cute kitten", "Photos of our gathering", "Beach, waves, sunset", "In car view, car on the road", "Screen display of traffic info", "Selfie in front of mirror", "Cheers"].randomElement()!
      
      var body: some View {
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
          }
          .onAppear{
              Task {
                  await photoSearcher.prepareModelForSearch()
              }
          }
      }
      
      private func clearSearch() {
          self.searchText = ""
          inputFocused = true
          photoSearcher.searchResultCode = .MODEL_PREPARED
      }

}
//
//#Preview {
//    ContentView()
//
//}
