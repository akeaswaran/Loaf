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
    public struct Style {
        public enum IconAlignment {
            case left
            case right
        }
        
        let backgroundColor: UIColor
        let textColor: UIColor
        let font: UIFont
        let icon: UIImage?
        let iconAlignment: IconAlignment
        
        public init(backgroundColor: UIColor, textColor: UIColor, font: UIFont, icon: UIImage?, iconAlignment: IconAlignment = .left) {
            self.backgroundColor = backgroundColor
            self.textColor = textColor
            self.font = font
            self.icon = icon
            self.iconAlignment = iconAlignment
        }
    }
    
    public enum State {
        case success
        case error
        case warning
        case info
        case custom(_ style: Style)
    }
    
    public enum Location {
        case top
        case bottom
    }
    
    public enum Direction {
        case left
        case right
        case vertical
        case fade
    }
    
    public enum Duration {
        case short
        case average
        case long
        case custom(_ duration: TimeInterval)
        
        var length: TimeInterval {
            switch self {
            case .short:   return 2.0
            case .average: return 4.0
            case .long:    return 8.0
            case .custom(let timeInterval):
                return timeInterval
            }
        }
    }
    
    // MARK: - Properties
    var message: String
    var state: State
    var location: Location
    var duration: Duration = .average
    var presentingDirection: Direction
    var dismissingDirection: Direction
    var completionHandler: (() -> Void)?
    
    private let sender: UIViewController
    
    // MARK: - Public methods
    public init(_ message: String,
                state: State = .info,
                location: Location = .bottom,
                presentingDirection: Direction = .vertical,
                dismissingDirection: Direction = .vertical,
                sender: UIViewController,
                completionHandler: (() -> Void)? = nil) {
        self.message = message
        self.state = state
        self.location = location
        self.presentingDirection = presentingDirection
        self.dismissingDirection = dismissingDirection
        self.sender = sender
        self.completionHandler = completionHandler
    }
    
    public func show(_ duration: Duration = .average) {
        self.duration = duration
        
        let toastVC = LoafViewController(self)
        sender.presentToast(toastVC)
    }
}

final class LoafViewController: UIViewController {
    var loaf: Loaf
    
    let label = UILabel()
    let imageView = UIImageView(image: nil)
    var font = UIFont.systemFont(ofSize: 14, weight: .medium)
    var transDelegate: UIViewControllerTransitioningDelegate
    
    init(_ toast: Loaf) {
        self.loaf = toast
        self.transDelegate = Manager(loaf: toast, size: .zero)
        super.init(nibName: nil, bundle: nil)
        
        if case let Loaf.State.custom(style) = loaf.state {
            self.font = style.font
        }
        
        let height = max(toast.message.heightWithConstrainedWidth(width: 240, font: font) + 12, 40)
        preferredContentSize = CGSize(width: 280, height: height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.text = loaf.message
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = .white
        label.font = font
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        view.addSubview(imageView)
        
        func constrainWithIconAlignment(_ alignment: Loaf.Style.IconAlignment) {
            //TODO: Support no image
            switch alignment {
            case .left:
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                    imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    imageView.heightAnchor.constraint(equalToConstant: 28),
                    imageView.widthAnchor.constraint(equalToConstant: 28),
                    
                    label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
                    label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
                    label.topAnchor.constraint(equalTo: view.topAnchor),
                    label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
            case .right:
                NSLayoutConstraint.activate([
                    imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                    imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    imageView.heightAnchor.constraint(equalToConstant: 28),
                    imageView.widthAnchor.constraint(equalToConstant: 28),
                    
                    label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                    label.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -4),
                    label.topAnchor.constraint(equalTo: view.topAnchor),
                    label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
            }
        }
        
        switch loaf.state {
        case .success:
            imageView.image = image(named: "success")
            view.backgroundColor = UIColor(hexString: "#2ecc71")
            constrainWithIconAlignment(.left)
        case .warning:
            imageView.image = image(named: "warning")
            view.backgroundColor = UIColor(hexString: "##f1c40f")
            constrainWithIconAlignment(.left)
        case .error:
            imageView.image = image(named: "error")
            view.backgroundColor = UIColor(hexString: "##e74c3c")
            constrainWithIconAlignment(.left)
        case .info:
            imageView.image = image(named: "info")
            view.backgroundColor = UIColor(hexString: "##34495e")
            constrainWithIconAlignment(.left)
        case .custom(style: let style):
            imageView.image = style.icon ?? image(named: "info")
            view.backgroundColor = style.backgroundColor
            imageView.tintColor = style.textColor
            label.textColor = style.textColor
            label.font = style.font
            constrainWithIconAlignment(style.iconAlignment)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + loaf.duration.length, execute: {
            self.dismiss(animated: true, completion: self.loaf.completionHandler)
        })
    }
    
    @objc private func handleTap() {
        dismiss(animated: true, completion: loaf.completionHandler)
    }
    
    private func image(named name: String) -> UIImage? {
        let bundle = Bundle(for: type(of: self))
        return UIImage(named: name, in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    }
}