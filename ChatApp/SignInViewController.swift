//
//  SignInViewController.swift
//  ChatApp
//
//  Created by user on 2019/06/09.
//  Copyright © 2019 Yusuke Yamauchi. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class SignInViewController: UIViewController,GIDSignInUIDelegate,GIDSignInDelegate {

    //チャット画面への遷移メソッド(黄色ボタンから次のやつへの紐づけは必要.Identiferは矢印につける)
    func transitionToChatRoom() {
        performSegue(withIdentifier: "toChatRoom", sender: self)//"toChatRoom"というIDで識別
    }

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        //Googleサインインに関するデリゲートメソッド
        //signIn:didSignInForUser:withError: メソッドで、Google ID トークンと Google アクセス トークンを
        //GIDAuthentication オブジェクトから取得して、Firebase 認証情報と交換します。
            if let error = error {
                print(error.localizedDescription)
                return
            }
            //userがいなけれればreturn
            guard let authentication = user.authentication else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
            
            
            //最後に、認証情報を使用して Firebase での認証を行います
            Auth.auth().signInAndRetrieveData(with: credential) { (authDataResult, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                print("\nSignin succeeded\n")
                self.transitionToChatRoom()
            }
    }


        /*** ここまで追加！ ***/


    
    @IBAction func tappedSignOut(_ sender: Any) {
    
        //サインアウトボタンを押したときの処理
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
                print("SignOut is succeeded")
                reloadInputViews()
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError)
            }
        }

    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance()?.uiDelegate = self
        GIDSignIn.sharedInstance()?.delegate = self
    }
    
    
    
    
}

