//
//  AWSS3Manager.swift
//  ScaiVision
//
//  Created by Liu on 2021/12/13.
//

import Foundation
import UIKit
import AWSS3


typealias completionBlock = (_ response: Any?, _ error: Error?) -> Void

class AWSS3Manager{
    static let shared = AWSS3Manager()
    private init(){
        
    }
    
    let bucketName = "scaivision-ios"
    
    func uploadImage(image: UIImage, completion: completionBlock?){
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            let error = NSError(domain:"", code: 402, userInfo: [NSLocalizedDescriptionKey:"invalid image"])
            completion?(nil, error)
            return
        }
        
        let tempPath = NSTemporaryDirectory() as String
        let fileName: String = ProcessInfo.processInfo.globallyUniqueString+(".jpg")
        let filePath = tempPath + "/" + fileName
        let fileUrl = URL(fileURLWithPath: filePath)
        
        do {
            try imageData.write(to: fileUrl)
            self.uploadFile(fileUrl: fileUrl, fileName: fileName, contenType: "image", completion: completion)
        } catch{
            let error = NSError(domain:"", code:402, userInfo:[NSLocalizedDescriptionKey: "invalid image"])
            completion?(nil, error)
        }
    }
    
    
    func uploadVideo(videoUrl: URL, completion: completionBlock?){
        let filename = self.getUniqueFileName(fileUrl: videoUrl)
        self.uploadFile(fileUrl: videoUrl, fileName: filename, contenType: "video", completion: completion)
    }
    
    func uploadFile(fileUrl: URL, fileName: String, contenType: String,  completion: completionBlock?){
        let expression = AWSS3TransferUtilityUploadExpression()
        
        
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if error == nil {
                    let url = AWSS3.default().configuration.endpoint.url
                    let publicURL = url?.appendingPathComponent(self.bucketName).appendingPathComponent(fileName)
                    print("Uploaded to:\(String(describing: publicURL))")
                    if let completionBlock = completion {
                        completionBlock(publicURL?.absoluteString, nil)
                    }
                    } else {
                        if let completionBlock = completion {
                            completionBlock(nil, error)
                        }
                    }
                })
        }
        let awsTransferUtility = AWSS3TransferUtility.default()
        awsTransferUtility.uploadFile(fileUrl, bucket: bucketName, key: fileName, contentType: contenType, expression: expression, completionHandler: completionHandler).continueWith { (task) -> Any? in
                if let error = task.error {
                    print("error is: \(error.localizedDescription)")
                }
                if let _ = task.result {
                        // your uploadTask
                }
                return nil
        }
    }
    
    func getUniqueFileName(fileUrl: URL) -> String {
        let strExt: String = "." + (URL(fileURLWithPath: fileUrl.absoluteString).pathExtension)
        return (ProcessInfo.processInfo.globallyUniqueString + (strExt))
    }
}

