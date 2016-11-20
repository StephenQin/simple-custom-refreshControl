//
//  SLRefreshControl.swift
//  自定义极简下拉刷新
//  备注清晰易于学习
//  Created by 秦－政 on 2016/05/30.
//  Copyright © 2016年 pete. All rights reserved.
//

import UIKit

// 自定义下拉刷新状态
private enum SLRefreshType: Int {
    // 下拉刷新状态
    case normal = 0
    // 松手就刷新
    case pulling = 1
    // 正在刷新
    case refreshing = 2
}
// 自定义控件大小的高度
private let SLRefreshControlHeight:CGFloat = 50

// 自定义下拉刷新控件
class SLRefreshControl: UIControl {
    // 记录当前的下拉刷新控件
    private var currentScrollview: UIScrollView?
    // 定义下拉刷新状态
    private var slRefreshType: SLRefreshType = .normal{
        didSet{
            switch slRefreshType {
            case .normal:
                // 下拉刷新
                print("下拉刷新")
                // 箭头重置，箭头显示，关闭风火轮动画，内容改成下拉刷新,恢复位置
                pulldownImageView.isHidden = false
                UIView.animate(withDuration: 0.25, animations: {
                    self.pulldownImageView.transform = CGAffineTransform.identity
                })
                indicatorView.stopAnimating()
                messageLabel.text = "下拉刷新"
                // 判断上一次刷新状态是正在属性，重置默认位置
                // oldValue 是上一次存储的值
                if oldValue == .refreshing {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.currentScrollview?.contentInset.top -= SLRefreshControlHeight
                    })
                }
                
                
            case.pulling:
                print("松手就刷新")
                // 箭头调转，内容变成松手就刷新
                UIView.animate(withDuration: 0.25, animations: { 
                    self.pulldownImageView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
                })
                messageLabel.text = "松手就刷新"
            case.refreshing:
                print("正在刷新")
                // 箭头隐藏，开启风火轮动画，内容改成正在刷新
                pulldownImageView.isHidden = true
                indicatorView.startAnimating()
                messageLabel.text = "正在刷新"
                // 设置停留位置  核心代码
                UIView.animate(withDuration: 0.25, animations: { 
                   self.currentScrollview?.contentInset.top += SLRefreshControlHeight
                })
                // 通知外界刷新数据
                sendActions(for: .valueChanged) // 核心代码
            }
        }
    }
    // 结束刷新
    func endRefreshing() {
        slRefreshType = .normal
    }
    // 获取父控件
    override func willMove(toSuperview newSuperview: UIView?) {
        // 判断是否是可以滚动的控件
        if let scrollView = newSuperview as? UIScrollView {
            // 表示是UIScrollView 的子类，可以监听其滚动
            // 可以使用kvo 监听 contentOffSet  监听新、旧值得改变 [.new,.old]
            scrollView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
            // 记录刷新视图控件
            currentScrollview = scrollView
        }
    }
    
    // kvo 监听方法
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let scrollView = currentScrollview else {
            return
        }
        // 执行至此表示scrollView不为nil
        // 计算临界点
        let maxY = -(scrollView.contentInset.top + SLRefreshControlHeight)
        // 获取偏移量
        let contentOffsetY = scrollView.contentOffset.y
        
        if scrollView.isDragging {
            // 表示拖动中  判断的核心
            if contentOffsetY < maxY && slRefreshType == .normal {
                slRefreshType = .pulling
            }else if contentOffsetY >= maxY && slRefreshType == .pulling {
                // normal 状态
                slRefreshType = .normal
            }
        }else{
            // 松手 只有pulling状态才能进入正刷新
            if slRefreshType == .pulling {
                // 刷新
                slRefreshType = .refreshing
            }
        }
    }
    deinit {
        // 移除kvo
        currentScrollview?.removeObserver(self, forKeyPath: "contentOffset")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 设置frame
        // 获取屏幕的宽度
        let screenWidth = UIScreen.main.bounds.size.width
        self.frame = CGRect(x: 0, y: -SLRefreshControlHeight, width: screenWidth, height: SLRefreshControlHeight)
        setupUI()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 添加控件设置约束
    private func setupUI(){
        backgroundColor = SLRandomColor()
        // 添加子控件
        addSubview(pulldownImageView)
        addSubview(messageLabel)
        addSubview(indicatorView)
        
        // 使用系统布局  关闭Autoresizing
        pulldownImageView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加约束
        addConstraint(NSLayoutConstraint(item: pulldownImageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: -35))
        addConstraint(NSLayoutConstraint(item: pulldownImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        addConstraint(NSLayoutConstraint(item: messageLabel, attribute: .leading, relatedBy: .equal, toItem: pulldownImageView, attribute: .trailing, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: messageLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        addConstraint(NSLayoutConstraint(item: indicatorView, attribute: .centerX, relatedBy: .equal, toItem: pulldownImageView, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: indicatorView, attribute: .centerY, relatedBy: .equal, toItem: pulldownImageView, attribute: .centerY, multiplier: 1, constant: 0))
    }
    
    // MARK: - 懒加载控件
    // 下拉箭头
    fileprivate lazy var pulldownImageView: UIImageView = UIImageView(image: UIImage(named: "tableview_pull_refresh"))
    // 下拉刷新内容
    fileprivate lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.text = "下拉刷新"
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = UIColor.gray
        return label
    }()
    // 风火轮
    fileprivate lazy var indicatorView:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
  
}
