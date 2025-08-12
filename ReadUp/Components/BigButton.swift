//
//  BigButton.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//
//
//import SwiftUI
//
//struct BigButton: View {
//    
//    @State var title: String
//    @State var hasIcon: Bool?
//    
//    var body: some View {
//            NavigationStack {
//                    NavigationLink(destination: ReadingSession()){
//                        HStack{
//                            Text(title)
//                                .font(.system(.title3, weight: .semibold))
//                                .foregroundStyle(.componentBackground)
//                    
//                            Image(systemName: "plus")
//                                .font(.system(.title3, weight: .semibold))
//                                .foregroundStyle(.componentBackground)
//                        }
//                        .frame(width: 361, height: 61)
//                        .background(
//                            RoundedRectangle(cornerRadius: 50)
//                                .foregroundStyle(.emphasis)
//                            )
//                    }
//            }
//        
//    }
//}
//
//#Preview {
//    BigButton(title: "Big button")
//}
