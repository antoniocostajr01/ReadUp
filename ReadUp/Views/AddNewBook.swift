//
//  AddNewBook.swift
//  ReadUp
//
//  Created by Antonio Costa on 08/08/25.
//
import PhotosUI
import SwiftUI

struct AddNewBook: View {
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    

    @State var title: String = ""
    
    @State var author: String = ""
    
    @State var numberOfPages: String = ""
    
    @State var details: String = ""
    
    @State var status: BookStatus?
    
    @State var imageData: Data? = nil
    
    @State var pickerBookImage: PhotosPickerItem?
    
    @State var bookCoverImage: Image?
    
    @State var navigateToLibrary = false
    
    
    var isFormValid: Bool{
        !title.isEmpty && !author.isEmpty && !numberOfPages.isEmpty && !details.isEmpty && imageData != nil && status != nil
    }
            
    var body: some View {
        
        ScrollView{
            VStack{
                if let bookCoverImage {
                    bookCoverImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 148, height: 211)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    PhotosPicker(selection: $pickerBookImage, matching: .images) {
                        VStack{
                            HStack{
                                Image(systemName: "camera.fill")
                                    .resizable()
                                    .frame(width: 60, height: 50)
                            }
                            .frame(width: 148, height: 211)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.emphasis, lineWidth: 1)
                                    .foregroundStyle(.componentBackground)
                            )
                            
                            Text(Localization.AddBook.accessGallery.string)
                                .foregroundStyle(.accent)
                        }
                    }
                }
            }
            .onChange(of: pickerBookImage) { oldValue, newValue in
                Task {
                    if let newImage = newValue {
                        if let loadData = try? await newImage.loadTransferable(type: Data.self) {
                            imageData = loadData
                            if let uiImage = UIImage(data: loadData) {
                                bookCoverImage = Image(uiImage: uiImage)
                            }
                        }
                    } else {
                        imageData = nil
                        bookCoverImage = nil
                    }
                }
            }
            
            
          
                TextField(Localization.AddBook.titlePlaceholder.string, text: $title, axis: .vertical)
                    .lineLimit(2)
                    .padding(.vertical, 12)
                    .padding(.leading, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.tabBarBackground)
                            .shadow(radius: 0.8, x:0, y: 3)
                    )
                    
                
                TextField(Localization.AddBook.authorPlaceholder.string, text: $author, axis: .vertical)
                    .lineLimit(1)
                    .padding(.vertical, 12)
                    .padding(.leading, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.tabBarBackground)
                            .shadow(radius: 0.8, x:0, y: 3)

                    )
                TextField(Localization.AddBook.pagesPlaceholder.string, text: $numberOfPages, axis: .vertical)
                    .keyboardType(.numberPad)
                    .scrollDismissesKeyboard(.automatic)
                    .padding(.vertical, 12)
                    .padding(.leading, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.tabBarBackground)
                            .shadow(radius: 0.8, x:0, y: 3)
                    )
                TextField(Localization.AddBook.detailsPlaceholder.string, text: $details, axis: .vertical)
                    .lineLimit(10...23)
                    .padding(.vertical, 12)
                    .padding(.leading, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.tabBarBackground)
                            .shadow(radius: 0.8, x:0, y: 3)

                    )
            
            
            Menu{
                ForEach(BookStatus.allCases, id: \.self) {enumStatus in
                    Button(enumStatus.displayName) {
                        status = enumStatus
                    }
                }
            } label: {
                HStack{
                    if status == nil{
                        Text("\(Localization.AddBook.selectStatus.string)")
                        Image(systemName: "chevron.up.chevron.down")
                    } else{
                        if let statusSelected = status {
                            Text(statusSelected.displayName)
                                .foregroundStyle(.mainText)
                                .font(.system(.title3, weight: .semibold))
                        }
                    }
                }
                .frame(width: 297, height: 61)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.emphasis, lineWidth: 2)
                    )
            }
            .padding(.top, 24)

            

            
            Button {
                
                guard let status, let imageData, let _ = Int(numberOfPages) else{
                    print("Invalid forms")
                    return
                }
                
                let book = Book(title: title, author: author, numberOfPages: Int(numberOfPages) ?? 0, details: details, status: status, imageData: imageData)
                
                modelContext.insert(book)
                
                do{
                    try modelContext.save()
                } catch {
                    print("Failed")
                }
                
                dismiss()
            } label: {
                Text(Localization.AddBook.saveBook.string)
                    .font(.system(.title3, weight: .semibold))
                    .foregroundStyle(.componentBackground)
                    .frame(width: 361, height: 61)
                    .background(
                        RoundedRectangle(cornerRadius: 50)
                            .foregroundStyle( isFormValid == false ? .secundaryLabel : .emphasis)
                    )
            }
            .padding(.top, 24)
            .disabled(!isFormValid)
            
        }
        .padding()
        .background(.backgroundPrimary)
        .onAppear{
            
        }
    }
}

#Preview {
    AddNewBook()
}
