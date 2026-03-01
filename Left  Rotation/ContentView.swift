//
//  ContentView.swift
//  Left  Rotation
//
//  Created by Hiro Ikezawa on 2023/03/08.
//

import SwiftUI
import Photos

//MARK: Document
final class ViewModel: ObservableObject {

    var first_time = true
  
    var img: UIImage = UIImage()

    private lazy var formatIdentifier = Bundle.main.bundleIdentifier!
    private let formatVersion = "1.0"

    
    func fetchPhotos () {
        // Sort the images by descending creation date and fetch the first 3
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1

        // Fetch the image assets
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)

        // If the fetch result isn't empty,
        // proceed with the image request
        if fetchResult.count > 0 {
            let totalImageCountNeeded = 1 // <-- The number of images to fetch
            fetchPhotoAtIndex(0, totalImageCountNeeded, fetchResult)
        }
    }

    // Repeatedly call the following method while incrementing
    // the index until all the photos are fetched
    func fetchPhotoAtIndex(_ index:Int, _ totalImageCountNeeded: Int, _ fetchResult: PHFetchResult<PHAsset>) {

        // Note that if the request is not set to synchronous
        // the requestImageForAsset will return both the image
        // and thumbnail; by setting synchronous to true it
        // will return just the thumbnail
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true

        // Perform the image request
        PHImageManager.default().requestImage(for: fetchResult.object(at: index) as PHAsset, targetSize: CGSize(width: 500, height: 500)  /*view.frame.size*/ , contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, _) in
            if let image = image {
                // Add the returned image to your array
                self.img = image
            }
            // If you haven't already reached the first
            // index of the fetch result and if you haven't
            // already stored all of the images you need,
            // perform the fetch request again with an
            // incremented index
//            if index + 1 < fetchResult.count && self.images.count < totalImageCountNeeded {
//                self.fetchPhotoAtIndex(index + 1, totalImageCountNeeded, fetchResult)
//            } else {
//                // Else you have completed creating your array
//                print("Completed array: \(self.images)")
//            }
        })
    }
    
    private func update(toPhoto: UIImage, completionHandler: @escaping ((Bool, Error?) -> Void)) {
        let options = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = { _ in
            return true
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1

        let requestFetchResult: PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        let asset: PHAsset = requestFetchResult.object(at: 0)
        asset.requestContentEditingInput(with: options) { input, info in
            guard let input = input else { fatalError("Can't get the content-editing input: \(info)") }

            DispatchQueue.global(qos: .userInitiated).async {
                let output = PHContentEditingOutput(contentEditingInput: input)
                let adjustmentData = PHAdjustmentData(formatIdentifier:self.formatIdentifier, formatVersion:self.formatVersion, data: "Left Rotation".data(using: .utf8)!)
                output.adjustmentData = adjustmentData

                let jpg = toPhoto.jpegData(compressionQuality: 0.9)

                do {
                    try jpg?.write(to: output.renderedContentURL)
                } catch let error {
                    fatalError("Can't save image to PHContentEditingOutput.renderedContentURL : \(error).")
                }

                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetChangeRequest(for: asset)
                    request.contentEditingOutput = output

                } completionHandler: { success, error in
                    completionHandler(success, error)
                }
            }
        }
    }
    
    
    func rotateFirstPic(){
        
        img = img.rotated(by: -90 * CGFloat.pi / 180)
    
        update(toPhoto: img) {success,err in
            print ("Error")
        }
    }
    
    func saveDefaults(){
        UserDefaults.standard.set(first_time, forKey: "first_time")
    }
    
    init(){
        first_time = UserDefaults.standard.bool(forKey: "first_time")

        
        fetchPhotos()
    }
    
}


extension UIImage {
    
    func rotated(by radians: CGFloat) -> UIImage {

        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size

        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, scale)
        if let context = UIGraphicsGetCurrentContext(), let cgImage = cgImage {
            context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.rotate(by: radians)
            context.scaleBy(x: 1, y: -1)
            context.translateBy(x: -size.width / 2, y: -size.height / 2)
            context.draw(cgImage, in: .init(origin: .zero, size: size))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return rotatedImage ?? self
        }
        return self
    }
}



//MARK: VIEW
struct ContentView: View {
    @StateObject var viewModel: ViewModel

    @State var image: UIImage?
    @State var imageType: String = ""
    @State var showingPicker = false
    @State var isAlert = true
    @State var isAlertFT = true

    var body: some View {
        VStack {
            
//            Button("画像を選択"){
//                showingPicker = true
//            }
//            .sheet(isPresented: $showingPicker) {
//                ImagePickerView(image: $image, sourceType: .library, imageType: $imageType)
//            }


            Image(uiImage: viewModel.img)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }
            
        
            
            Spacer()
                .alert("Left Rotation", isPresented: $isAlert){
                    Button("はい"){
                        // ボタン1が押された時の処理
                        viewModel.rotateFirstPic()
                    }
                    Button("いいえ"){
                        // ボタン2が押された時の処理
                        return
                    }
                } message: {
                    Text("左回転しますか？")
                }

            
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ViewModel())
    }
}



struct ImagePickerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIImagePickerController
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    enum SourceType {
        case camera
        case library
    }
    var sourceType: SourceType
    @Binding var imageType: String
    var allowsEditing: Bool = false

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage {
                parent.image = image
            } else if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            
            let assetPath = info[UIImagePickerController.InfoKey.referenceURL] as! NSURL
            if (assetPath.absoluteString?.hasSuffix("JPG"))! {
                parent.imageType = "jpg"
            }
            else if (assetPath.absoluteString?.hasSuffix("PNG"))! {
                parent.imageType = "png"
            }
            else if (assetPath.absoluteString?.hasSuffix("HEIC"))! {
                parent.imageType = "heic"
            }
            else {
                parent.imageType = ""
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let viewController = UIImagePickerController()
        viewController.delegate = context.coordinator
        switch sourceType {
        case .camera:
            viewController.sourceType = UIImagePickerController.SourceType.camera
        case .library:
            viewController.sourceType = UIImagePickerController.SourceType.photoLibrary
        }
        viewController.allowsEditing = allowsEditing
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
}


