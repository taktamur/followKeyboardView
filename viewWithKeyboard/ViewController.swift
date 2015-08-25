//
//  ViewController.swift
//  viewWithKeyboard
//
//  Created by 田村孝文 on 2015/08/24.
//  Copyright (c) 2015年 田村孝文. All rights reserved.
//


/*
前提：
- Storyboard+AutoLayoutで配置
- キーボード追従するViewの下側に制約を配置し、この制約をアニメーションさせる。
ポイント：
- キーボードの表示/非表示は、NSNotificationCenterでUIKeyboardWill{Show|Hide}Notification を監視すれば良い。
- Notificationの監視は、「ViewControllerが表示されている時」だけにするのが良い。他の画面でのキーボード表示に反応してしまう場合があるから
- Notificationには「キーボード表示アニメーションの時間」と「どの位置にキーボードが表示されるのか」の情報がuserInfoに含まれるので、それを使ってAutoLayoutの制約の値をアニメーションで変化させる
- AutoLayoutの制約をアニメーションさせるには、制約の値を書き換えた後、UIView.animationでlayoutIfNeed()を呼び出す
- タブバーが表示されているかどうかを考慮する必要がある。ViewControllerのbottomLayoutGuide.lengthでタブバーの高さが取れるので、これを使う
- もしも「テーブルビューで」これを行う場合には、UITableViewControllerは使えない。これはキーボード追従するViewを、「画面下に貼り付ける」というStoryboardが作れないから。
*/
import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.startObserveKeyboardNotification()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopOberveKeyboardNotification()
    }

    /** キーボードを閉じるIBAction */
    @IBAction func tapView(sender: AnyObject) {
        self.textView.resignFirstResponder()
    }
}

/** キーボード追従に関連する処理をまとめたextenstion */
extension ViewController{
    /** キーボードのNotificationを購読開始 */
    func startObserveKeyboardNotification(){
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector:"willShowKeyboard:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector:"willHideKeyboard:", name: UIKeyboardWillHideNotification, object: nil)
    }
    /** キーボードのNotificationの購読停止 */
    func stopOberveKeyboardNotification(){
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    /** キーボードが開いたときに呼び出されるメソッド */
    func willShowKeyboard(notification:NSNotification){
        NSLog("willShowKeyboard called.")
        let duration = notification.duration()
        let rect     = notification.rect()
        if let duration=duration,rect=rect {
            // ここで「self.bottomLayoutGuide.length」を使っている理由：
            // tabBarの表示/非表示に応じて制約の高さを変えないと、
            // viewとキーボードの間にtabBar分の隙間が空いてしまうため、
            // ここでtabBar分の高さを計算に含めています。
            // - tabBarが表示されていない場合、self.bottomLayoutGuideは0となる
            // - tabBarが表示されている場合、self.bottomLayoutGuideにはtabBarの高さが入る
            
            // layoutIfNeeded()→制約を更新→UIView.animationWithDuration()の中でlayoutIfNeeded() の流れは
            // 以下を参考にしました。
            // http://qiita.com/caesar_cat/items/051cda589afe45255d96
            self.view.layoutIfNeeded()
            self.bottomConstraint.constant=rect.size.height - self.bottomLayoutGuide.length;
            UIView.animateWithDuration(duration, animations: { () -> Void in
                self.view.layoutIfNeeded()  // ここ、updateConstraint()でも良いのかと思ったけど動かなかった。
            })
        }
    }
    /** キーボードが閉じたときに呼び出されるメソッド */
    func willHideKeyboard(notification:NSNotification){
        NSLog("willHideKeyboard called.")
        let duration = notification.duration()
        if let duration=duration {
            self.view.layoutIfNeeded()
            self.bottomConstraint.constant=0
            UIView.animateWithDuration(duration,animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
    }
}

/** キーボード表示通知の便利拡張 */
extension NSNotification{
    /** 通知から「キーボードの開く時間」を取得 */
    func duration()->NSTimeInterval?{
        let duration:NSTimeInterval? = self.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double
        return duration;
    }
    /** 通知から「表示されるキーボードの表示位置」を取得 */
    func rect()->CGRect?{
        let rowRect:NSValue? = self.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        let rect:CGRect? = rowRect?.CGRectValue()
        return rect
    }
    
}


