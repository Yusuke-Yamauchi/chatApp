//
//  ChatViewController.swift
//  ChatApp
//
//  Created by user on 2019/06/09.
//  Copyright © 2019 Yusuke Yamauchi. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Firebase

class ChatViewController: MessagesViewController {
    
    //private:外部から書き換えられない
    //databaseref　データの塊　user:ユーザー情報
    private var ref: DatabaseReference! //firebaseのデータベース
    private var user:User!
    private var handle:DatabaseHandle!
    var messageList : [Message] = []
    var sendData: [String:Any] = [:]
    var readData: [[String: Any]] = []
    
    //日時をどこまで(秒とか)表示するか
    let dateFormatter: DateFormatter = DateFormatter()
    
    override func viewWillAppear(_ animated: Bool) {
        updateViewWhenMessageAdded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ref.child("chats").removeObserver(withHandle: handle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        user = Auth.auth().currentUser
        
        //各種デリゲートをこのVCに設定
        messagesCollectionView.messagesDataSource = self as MessagesDataSource
        messagesCollectionView.messagesLayoutDelegate = self as MessagesLayoutDelegate
        messagesCollectionView.messagesDisplayDelegate = self as MessagesDisplayDelegate
        messagesCollectionView.messageCellDelegate = self as MessageCellDelegate
        messageInputBar.delegate = self as InputBarAccessoryViewDelegate
        
        // メッセージ入力時に一番下までスクロール
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        //日付の表示設定
        dateFormatter.dateStyle = .medium
        //時間
        dateFormatter.timeStyle = .short
        //タイムゾーン
        dateFormatter.locale = Locale(identifier: "ja_JP")
        
    }
    
    
    func sendMessageToFirebase(text:String){
        if !sendData.isEmpty{sendData = [:]} //初期化
        let sendRef = ref.child("chats").childByAutoId()  //自動生成
        let messageID = sendRef.key! //自動生成を格納
        
        sendData = ["senderName":user.displayName,
                    "senderID":user.uid,"content":text,"createdAt":dateFormatter.string(from: Date()),
                    "messageID":messageID]
        
        sendRef.setValue(sendData)
        
        
    }
    
    
    //メッセージが追加された際に読み込みして画面を更新する
    func updateViewWhenMessageAdded() {
      
            
        //最大25個を降順で取り出してくる(最新25件をとってる)
         handle = ref.child("chats").queryLimited(toLast: 25).queryOrdered(byChild: "createdAt").observe(.value){(snapshot:DataSnapshot)in DispatchQueue.main.async {
            self.snapshotToArray(snapshot:snapshot)  //スナップショットを配列(readData)に入れる処理。下に定義
            self.displayMessage()
            print("readData\(self.readData)")
            }}
    
    
    }
    
    
    //データベースから読み込んだデータを配列(readData)に格納するメソッド(どちらかというとふfirebaseの使い方)
    func snapshotToArray(snapshot: DataSnapshot){
        if !readData.isEmpty {readData = [] }
        if snapshot.children.allObjects as? [DataSnapshot] != nil  {
            let snapChildren = snapshot.children.allObjects as? [DataSnapshot]
            for snapChild in snapChildren! {
                if let postDict = snapChild.value as? [String: Any] {
                    self.readData.append(postDict)
                }
            }
        }
    }
    //メッセージの画面表示に関するメソッド
    func displayMessage() {
        if !messageList.isEmpty {messageList = []}
        for item in readData {
            print("item: \(item)\n")
            let message = Message(
                sender: Sender(id: item["senderID"] as! String,displayName: item["senderName"] as! String),
                messageId: item["messageID"] as! String,
                sentDate: self.dateFormatter.date(from: item["createdAt"] as! String)!,
                kind: MessageKind.text(item["content"] as! String)
            )
            messageList.append(message)
        }
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom()
    }

    
    
} //end class ChatViewController


extension ChatViewController: MessagesDataSource {
    //自分の情報を設定
    func currentSender() -> SenderType {
        return Sender(senderId: user.uid, displayName: user.displayName!)
    }
    //表示するメッセージの数
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    //メッセージの実態
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section] as MessageType
    }
    
    //セルの上の文字
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(
                string: MessageKitDateFormatter.shared.string(from: message.sentDate),
                attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                             NSAttributedString.Key.foregroundColor: UIColor.darkGray]
            )
        }
        return nil
    }
    
    // メッセージの上の文字
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    // メッセージの下の文字
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
}

// メッセージの見た目に関するdelegate
extension ChatViewController: MessagesDisplayDelegate {
    
    // メッセージの色を変更
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        //isfrom...:if文的な｡　ログインしてるひとからのメッセージなら白
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    // メッセージの背景色を変更している
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ?
            UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) :
            UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }
    
    // メッセージの枠にしっぽを付ける
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    // アイコンをセット
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // message.sender.displayNameとかで送信者の名前を取得できるので
        // そこからイニシャルを生成するとよい
        let avatar = Avatar(initials: message.sender.displayName)
        avatarView.set(avatar: avatar)
    }
}


// 各ラベルの高さを設定（デフォルト0なので必須）、メッセージの表示位置に関するデリゲート
extension ChatViewController: MessagesLayoutDelegate {
    
    //cellTopLabelAttributedTextを表示する高さ
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.section % 3 == 0 { return 10 }
        return 0
    }
    
    //messageTopLabelAttributedTextを表示する高さ
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
    
    //messageBottomLabelAttributedTextを表示する高さ
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
}

extension ChatViewController: MessageCellDelegate {
    // メッセージをタップした時の挙動
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    // メッセージ送信ボタンを押されたとき
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        sendMessageToFirebase(text: text) //他のところに置かないこと
        inputBar.inputTextView.text = ""
        messagesCollectionView.scrollToBottom()
        
        
    }
}
