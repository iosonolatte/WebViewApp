//
//  ViewController.swift
//  WebViewApp
//
//  Created by nxgdev40 on 4/7/19.
//  Copyright © 2019 nxgdev40. All rights reserved.
//

import UIKit
import WebKit
import WebViewJavascriptBridge

class ViewController: UIViewController {
    
    var webView: WKWebView!
    var bridge: WebViewJavascriptBridge!

    fileprivate let trustedDomains = ["sxgebtsgv097.sg.uobnet.com", "sxgebtsgv099.sg.uobnet.com", "jiraagile.sg.uobnet.com"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        view.addSubview(webView)
        setupJSBridge()
        loadContent()
    }
    
    private func setupJSBridge() {
        bridge = WebViewJavascriptBridge(forWebView: webView)
        bridge.registerHandler("showAlert", handler: { data, responseCallback in
            print("ShowAlert called with:\(String(describing: data))")
            self.showPopup()
        })
        
        bridge.registerHandler("openCamera", handler: { data, responseCallback in
            print("openCamera called with:\(String(describing: data))")
            self.openCamera()
        })
        
        bridge.registerHandler("makeCall", handler: { data, responseCallback in
            print("openCamera called with:\(String(describing: data))")
            self.makeCall(number: "+6586549179")
        })
    }
    
    private func showPopup() {
        let alertVC = UIAlertController(title: "Message", message: "Hello from Swift ", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alertVC, animated: true)
    }
    
    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    private func makeCall(number: String) {
        let phoneUrlString = number.replacingOccurrences(of: " ", with: "")
        guard let phoneUrl = URL(string: "tel://\(phoneUrlString)") else {
            return
        }
        UIApplication.shared.open(phoneUrl, options: [:])
    }
    
    private func loadContent() {
        do {
            guard let filePath = Bundle.main.path(forResource: "demo_page", ofType: "html")
                else {
                    // File Error
                    print ("File reading error")
                    return
            }
            
            let contents =  try String(contentsOfFile: filePath, encoding: .utf8)
            let baseUrl = URL(fileURLWithPath: filePath)
            webView.loadHTMLString(contents as String, baseURL: baseUrl)
        }
        catch {
            print ("File HTML error")
        }
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if trustedDomains.contains(challenge.protectionSpace.host) {
                completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        let imageString = image.jpegData(compressionQuality: 0.3)?.base64EncodedString()
        print(imageString)
        dismiss(animated: true, completion: {
            self.bridge.callHandler("photoTaken", data: imageString)
        })
    }
}

