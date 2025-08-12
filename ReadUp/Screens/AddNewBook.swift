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
    
    @State var status: BookStatus = .abandoned
    
    @State var imageData: Data? = nil
    
    @State var pickerBookImage: PhotosPickerItem?
    
    @State var bookCoverImage: Image?
    
    @State var navigateToLibrary = false
    
    
    var isFormValid: Bool{
        !title.isEmpty && !author.isEmpty && !numberOfPages.isEmpty && !details.isEmpty && imageData != nil
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
                                    .frame(width: 60, height: 60)
                            }
                            .frame(width: 148, height: 211)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundStyle(.weekDayBackground)
                            )
                            
                            Text("Click here to acesss galery")
                                .foregroundStyle(.secundaryLabel)
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
            
            
            VStack{
                TextField("Title", text: $title, axis: .vertical)
                    .lineLimit(2)
                    .padding(.vertical, 12)
                    .padding(.leading, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.tabBarBackground)
                    )
                TextField("Author", text: $author, axis: .vertical)
                    .lineLimit(2)
                    .padding(.vertical, 12)
                    .padding(.leading, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.tabBarBackground)
                    )
                TextField("Number of pages", text: $numberOfPages, axis: .vertical)
                    .keyboardType(.numberPad)
                    .scrollDismissesKeyboard(.automatic)
                    .lineLimit(2)
                    .padding(.vertical, 12)
                    .padding(.leading, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.tabBarBackground)
                    )
                TextField("Details", text: $details, axis: .vertical)
                    .lineLimit(10...23)
                    .padding(.vertical, 12)
                    .padding(.leading, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.tabBarBackground)
                    )
            }
            
            Menu{
                ForEach(BookStatus.allCases, id: \.self) {enumStatus in
                    Button(enumStatus.rawValue) {
                        status = enumStatus
                    }
                }
            } label: {
                Text("Book Status: \(status.rawValue)")
            }
            

            
            Button {
                
                let book = Book(title: title, author: author, numberOfPages: Int(numberOfPages) ?? 0, details: details, status: status, imageData: imageData!)
                
                modelContext.insert(book)
                
                do{
                    try modelContext.save()
                } catch {
                    print("Failed")
                }
                
                dismiss()
            } label: {
                Text("Save Session")
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
    }
}

#Preview {
    AddNewBook()
}
