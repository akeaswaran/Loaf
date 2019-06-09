//
//  Loaf.swift
//  Loaf
//
//  Created by Mat Schmid on 2019-02-04.
//  Copyright © 2019 Mat Schmid. All rights reserved.
//

import UIKit

final public class Loaf {
    
    // MARK: - Specifiers
    
    /// Define a custom style for the loaf.
    public struct Style {
        /// Specifies the position of the icon on the loaf. (Default is `.left`)
        ///
        /// - left: The icon will be on the left of the text
        /// - right: The icon will be on the right of the text
        public enum IconAlignment {
            case left
            case right
        }
        
        /// The background color of the loaf.
        let backgroundColor: UIColor
        
        /// The color of the label's title text
        let messageLabelTextColor: UIColor
        
        /// The color of the icon (Assuming it's rendered as template)
        let tintColor: UIColor
        
        /// The font of the message label
        let messageLabelFont: UIFont
        
        /// The color of the label's title text
        let titleLabelTextColor: UIColor
        
        /// The font of the title label
        let titleLabelFont: UIFont
        
        /// The icon on the loaf
        let icon: UIImage?
        
        let textAlignment: NSTextAlignment
        
        /// The position of the icon
        let iconAlignment: IconAlignment
        
        // The top and bottom margins to use for the labels
        let verticalMargin: CGFloat
        
        // The left and right margins to use for the labels
        let horizontalMargin: CGFloat
        
        // The width to use for the view
        let width: CGFloat
        
        public init(backgroundColor: UIColor, messageLabelTextColor: UIColor = .lightText, titleLabelTextColor: UIColor = .white, tintColor: UIColor = .white, messageLabelFont: UIFont = UIFont.systemFont(ofSize: 12, weight: .regular), titleLabelFont: UIFont = UIFont.systemFont(ofSize: 14, weight: .medium), icon: UIImage? = Icon.info, textAlignment: NSTextAlignment = .left, iconAlignment: IconAlignment = .left, verticalMargin: CGFloat = 10.0, horizontalMargin: CGFloat = 10.0, width: CGFloat = 280.0) {
            self.backgroundColor = backgroundColor
            self.messageLabelTextColor = messageLabelTextColor
            self.tintColor = tintColor
            self.messageLabelFont = messageLabelFont
            self.titleLabelTextColor = titleLabelTextColor
            self.titleLabelFont = titleLabelFont
            self.icon = icon
            self.textAlignment = textAlignment
            self.iconAlignment = iconAlignment
            self.verticalMargin = verticalMargin
            self.horizontalMargin = horizontalMargin
            self.width = width
        }
    }
    
    /// Defines the loaf's status. (Default is `.info`)
    ///
    /// - success: Represents a success message
    /// - error: Represents an error message
    /// - warning: Represents a warning message
    /// - info: Represents an info message
    /// - custom: Represents a custom loaf with a specified style.
    public enum State {
        case success
        case error
        case warning
        case info
        case custom(Style)
    }
    
    /// Defines the loaction to display the loaf. (Default is `.bottom`)
    ///
    /// - top: Top of the display
    /// - bottom: Bottom of the display
    public enum Location {
        case top
        case bottom
    }
    
    /// Defines either the presenting or dismissing direction of loaf. (Default is `.vertical`)
    ///
    /// - left: To / from the left
    /// - right: To / from the right
    /// - vertical: To / from the top or bottom (depending on the location of the loaf)
    public enum Direction {
        case left
        case right
        case vertical
    }
    
    /// Defines the duration of the loaf presentation. (Default is .`avergae`)
    ///
    /// - short: 2 seconds
    /// - average: 4 seconds
    /// - long: 8 seconds
    /// - custom: A custom duration (usage: `.custom(5.0)`)
    public enum Duration {
        case veryShort
        case short
        case average
        case long
        case custom(TimeInterval)
        
        var length: TimeInterval {
            switch self {
            case .veryShort: return 1.0
            case .short:   return 2.0
            case .average: return 4.0
            case .long:    return 8.0
            case .custom(let timeInterval):
                return timeInterval
            }
        }
    }
    
    /// Icons used in basic states
    public enum Icon {
        public static let success = Icons.imageOfSuccess().withRenderingMode(.alwaysTemplate)
        public static let error = Icons.imageOfError().withRenderingMode(.alwaysTemplate)
        public static let warning = Icons.imageOfWarning().withRenderingMode(.alwaysTemplate)
        public static let info = Icons.imageOfInfo().withRenderingMode(.alwaysTemplate)
    }
    
    // MARK: - Properties
    var title: String?
    var message: String
    var state: State
    var location: Location
    var duration: Duration = .average
    var presentingDirection: Direction
    var dismissingDirection: Direction
    var completionHandler: ((Bool) -> Void)? = nil
    weak var sender: UIViewController?
    
    // MARK: - Public methods
    public init(title: String? = nil, message: String,
                state: State = .info,
                location: Location = .bottom,
                presentingDirection: Direction = .vertical,
                dismissingDirection: Direction = .vertical,
                sender: UIViewController) {
        self.title = title
        self.message = message
        self.state = state
        self.location = location
        self.presentingDirection = presentingDirection
        self.dismissingDirection = dismissingDirection
        self.sender = sender
    }
    
    /// Show the loaf for a specified duration. (Default is `.average`)
    ///
    /// - Parameter duration: Length the loaf will be presented
    public func show(_ duration: Duration = .average, completionHandler: ((Bool) -> Void)? = nil) {
        self.duration = duration
        self.completionHandler = completionHandler
        LoafManager.shared.queueAndPresent(self)
    }
}

final fileprivate class LoafManager: LoafDelegate {
    static let shared = LoafManager()
    
    fileprivate var queue = Queue<Loaf>()
    fileprivate var isPresenting = false
    
    fileprivate func queueAndPresent(_ loaf: Loaf) {
        queue.enqueue(loaf)
        presentIfPossible()
    }
    
    func loafDidDismiss() {
        isPresenting = false
        presentIfPossible()
    }
    
    fileprivate func presentIfPossible() {
        guard isPresenting == false, let loaf = queue.dequeue(), let sender = loaf.sender else { return }
        isPresenting = true
        let loafVC = LoafViewController(loaf)
        loafVC.delegate = self
        sender.presentToast(loafVC)
    }
}

protocol LoafDelegate: AnyObject {
    func loafDidDismiss()
}

final class LoafViewController: UIViewController {
    var loaf: Loaf
    
    let titleLabel = UILabel()
    var titleLabelFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    let messageLabel = UILabel()
    let imageView = UIImageView(image: nil)
    var verticalMargin: CGFloat = 10.0
    var loafWidth: CGFloat = 280
    var horizontalMargin: CGFloat = 10.0
    var messageLabelFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    var textAlignment: NSTextAlignment = .left
    var transDelegate: UIViewControllerTransitioningDelegate
    weak var delegate: LoafDelegate?
    
    init(_ toast: Loaf) {
        self.loaf = toast
        self.transDelegate = Manager(loaf: toast, size: .zero)
        super.init(nibName: nil, bundle: nil)
        
        if case let Loaf.State.custom(style) = loaf.state {
            self.messageLabelFont = style.messageLabelFont
            self.titleLabelFont = style.titleLabelFont
            self.textAlignment = style.textAlignment
            self.verticalMargin = style.verticalMargin
            self.horizontalMargin = style.horizontalMargin
            self.loafWidth = style.width
        }
        
        var height = max(toast.message.heightWithConstrainedWidth(width: 240, font: messageLabelFont) + ((self.verticalMargin * 2) * 0.6), 40)
        if (loaf.title != nil) {
            height = max(toast.message.heightWithConstrainedWidth(width: 240, font: messageLabelFont) + 4 + toast.title!.heightWithConstrainedWidth(width: 240, font: titleLabelFont) + (self.verticalMargin * 2), 40)
        }
        preferredContentSize = CGSize(width: self.loafWidth, height: height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageLabel.text = loaf.message
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.textColor = .white
        messageLabel.font = messageLabelFont
        messageLabel.textAlignment = textAlignment
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
//        messageLabel.sizeToFit()
//        messageLabel.layer.borderColor = UIColor.blue.cgColor
//        messageLabel.layer.borderWidth = 2.0
        
        if (loaf.title != nil) {
            titleLabel.text = loaf.title
            titleLabel.numberOfLines = 0
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.textColor = .white
            titleLabel.font = titleLabelFont
            titleLabel.textAlignment = textAlignment
            titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
//            titleLabel.sizeToFit()
//            titleLabel.layer.borderColor = UIColor.red.cgColor
//            titleLabel.layer.borderWidth = 2.0
        }
        
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        switch loaf.state {
            case .success:
                imageView.image = Loaf.Icon.success
                view.backgroundColor = UIColor(hexString: "#2ecc71")
                constrainWithIconAlignment(.left)
            case .warning:
                imageView.image = Loaf.Icon.warning
                view.backgroundColor = UIColor(hexString: "##f1c40f")
                constrainWithIconAlignment(.left)
            case .error:
                imageView.image = Loaf.Icon.error
                view.backgroundColor = UIColor(hexString: "##e74c3c")
                constrainWithIconAlignment(.left)
            case .info:
                imageView.image = Loaf.Icon.info
                view.backgroundColor = UIColor(hexString: "##34495e")
                constrainWithIconAlignment(.left)
            case .custom(style: let style):
                imageView.image = style.icon
                view.backgroundColor = style.backgroundColor
                imageView.tintColor = style.tintColor
                if (title != nil) {
                    titleLabel.textColor = style.titleLabelTextColor
                    titleLabel.font = style.titleLabelFont
                }
                messageLabel.textColor = style.messageLabelTextColor
                messageLabel.font = style.messageLabelFont
                constrainWithIconAlignment(style.iconAlignment, showsIcon: imageView.image != nil)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + loaf.duration.length, execute: {
            self.dismiss(animated: true) { [weak self] in
                self?.delegate?.loafDidDismiss()
                self?.loaf.completionHandler?(false)
            }
        })
    }
    
    @objc private func handleTap() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.loafDidDismiss()
            self?.loaf.completionHandler?(true)
        }
    }
    
    private func constrainWithIconAlignment(_ alignment: Loaf.Style.IconAlignment, showsIcon: Bool = true) {
        if (loaf.title != nil) {
            view.addSubview(titleLabel)
        }
        view.addSubview(messageLabel)
        
        if showsIcon {
            view.addSubview(imageView)
            
            switch alignment {
            case .left:
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:  self.horizontalMargin),
                    imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    imageView.heightAnchor.constraint(equalToConstant: 28),
                    imageView.widthAnchor.constraint(equalToConstant: 28)
                ])

                if (loaf.title != nil) {
                    NSLayoutConstraint.activate([
                        titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: self.verticalMargin),
                        titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -1 * self.horizontalMargin),
                        titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
                        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
                        messageLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
                        messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
                        messageLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -1 * self.verticalMargin)
                    ])
                    titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
                    messageLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
                } else {
                    NSLayoutConstraint.activate([
                        messageLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
                        messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
                        messageLabel.topAnchor.constraint(equalTo: view.topAnchor),
                        messageLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                    ])
                }
            case .right:
                NSLayoutConstraint.activate([
                    imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -1 * self.horizontalMargin),
                    imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    imageView.heightAnchor.constraint(equalToConstant: 28),
                    imageView.widthAnchor.constraint(equalToConstant: 28),
                ])
                
                if (loaf.title != nil) {
                    NSLayoutConstraint.activate([
                        titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: self.verticalMargin),
                        titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:  self.horizontalMargin),
                        titleLabel.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -4),
                        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
                        messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:  self.horizontalMargin),
                        messageLabel.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -4),
                        messageLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -1 * self.verticalMargin)
                    ])
                    titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
                    messageLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
                } else {
                    NSLayoutConstraint.activate([
                        messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:  self.horizontalMargin),
                        messageLabel.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -4),
                        messageLabel.topAnchor.constraint(equalTo: view.topAnchor),
                        messageLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                    ])
                }
            }
        } else {
            if (loaf.title != nil) {
                NSLayoutConstraint.activate([
                    titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: self.verticalMargin),
                    titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:  self.horizontalMargin),
                    titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -1 * self.horizontalMargin),
                    messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
                    messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:  self.horizontalMargin),
                    messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -1 * self.horizontalMargin),
                    messageLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -1 * self.verticalMargin)
                ])
                titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
                messageLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
            } else {
                NSLayoutConstraint.activate([
                    messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:  self.horizontalMargin),
                    messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -1 * self.horizontalMargin),
                    messageLabel.topAnchor.constraint(equalTo: view.topAnchor),
                    messageLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
            }
        }
    }
}

private struct Queue<T> {
    fileprivate var array = [T]()
    
    mutating func enqueue(_ element: T) {
        array.append(element)
    }
    
    mutating func dequeue() -> T? {
        if array.isEmpty {
            return nil
        } else {
            return array.removeFirst()
        }
    }
}

