//
//  VisilabsPopupUIElements.swift
//  VisilabsIOS
//
//  Created by Said Alır on 6.11.2020.
//

import Foundation
import UIKit

extension VisilabsPopupDialogDefaultView {
    
    internal func setCloseButton() -> UIButton {
        let closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.contentHorizontalAlignment = .right
        closeButton.clipsToBounds = false
        closeButton.setTitleColor(UIColor.white, for: .normal)
        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 35.0, weight: .regular)
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 2.5, left: 2.5, bottom: 2.5, right: 2.5)
        return closeButton
    }
    
    internal func setImageView() -> UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }
    
    internal func setTitleLabel() -> UILabel {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(white: 0.4, alpha: 1)
        titleLabel.font = .boldSystemFont(ofSize: 14)
        return titleLabel
    }
    
    internal func setMessageLabel() -> UILabel {
        let messageLabel = UILabel(frame: .zero)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = UIColor(white: 0.6, alpha: 1)
        messageLabel.font = .systemFont(ofSize: 14)
        return messageLabel
    }
    
    internal func setNpsView() -> CosmosView {
        var settings = CosmosSettings()
        settings.filledColor = UIColor.systemYellow
        settings.emptyColor = UIColor.white
        settings.filledBorderColor = UIColor.white
        settings.emptyBorderColor = UIColor.systemYellow
        settings.fillMode = .half
        settings.starSize = 40.0
        settings.disablePanGestures = true
        let npsView = CosmosView(settings: settings)
        npsView.translatesAutoresizingMaskIntoConstraints = false
        npsView.rating = 0.0
        return npsView
    }
    
    internal func setEmailTF() -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .natural
        textField.font = .systemFont(ofSize: 14)
        textField.textColor = .white
        textField.placeholder = "E-posta adresinizi giriniz."
        textField.borderStyle = .line
        textField.delegate = self
        return textField
    }
    
    internal func setCheckbox() -> Checkbox {
        let check = Checkbox(frame: .zero)
        check.checkmarkStyle = .tick
        check.borderStyle = .square
        check.uncheckedBorderColor = .white
        check.checkedBorderColor = .white
        check.checkmarkColor = .white
        return check
    }
    
    internal func setTermsButton() -> UIButton {
        let button = UIButton(frame: .zero)
        let text = "Kullanım koşullarını okuldum ve kabul ediyorum."
        button.setTitle(text, for: .normal)
        button.tintColor = .white
        button.titleLabel?.textColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.addTarget(self, action: #selector(termsButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    internal func setResultLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.textAlignment = .natural
        label.font = .systemFont(ofSize: 12)
        return label
    }
    
    internal func setSliderStepRating() -> VisilabsSliderStep {
        
        let sliderStepRating = VisilabsSliderStep()
        
        sliderStepRating.stepImages =   [getUIImage(named:"terrible")!, getUIImage(named:"bad")!, getUIImage(named:"okay")!, getUIImage(named:"good")!,getUIImage(named:"great")!, ]
        sliderStepRating.tickImages = [getUIImage(named:"unTerrible")!, getUIImage(named:"unBad")!, getUIImage(named:"unOkay")!, getUIImage(named:"unGood")!,getUIImage(named:"unGreat")!, ]
        
        sliderStepRating.tickTitles = ["Berbat", "Kötü", "Normal", "İyi", "Harika"]
        
        sliderStepRating.minimumValue = 1
        sliderStepRating.maximumValue = Float(sliderStepRating.stepImages!.count) + sliderStepRating.minimumValue - 1.0
        sliderStepRating.stepTickColor = UIColor.clear
        sliderStepRating.stepTickWidth = 20
        sliderStepRating.stepTickHeight = 20
        sliderStepRating.trackHeight = 2
        sliderStepRating.value = 1
        sliderStepRating.trackColor = .clear
        sliderStepRating.enableTap = true
        sliderStepRating.sliderStepDelegate = self
        sliderStepRating.translatesAutoresizingMaskIntoConstraints = false
        
        sliderStepRating.contentMode = .redraw //enable redraw on rotation (calls setNeedsDisplay)
        
        if sliderStepRating.enableTap {
            let tap = UITapGestureRecognizer(target: sliderStepRating, action: #selector(VisilabsSliderStep.sliderTapped(_:)))
            self.addGestureRecognizer(tap)
        }
        
        sliderStepRating.addTarget(sliderStepRating, action: #selector(VisilabsSliderStep.movingSliderStepValue), for: .valueChanged)
        sliderStepRating.addTarget(sliderStepRating, action: #selector(VisilabsSliderStep.didMoveSliderStepValue), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return sliderStepRating
    }
    
    private func getUIImage(named: String) -> UIImage?{
        let bundle = Bundle(identifier: "com.relateddigital.visilabs")
        return UIImage(named: named, in : bundle, compatibleWith: nil)!.resized(withPercentage: CGFloat(0.75))
    }
    
    internal func baseSetup(_ notification: VisilabsInAppNotification) {
        if let bgColor = notification.backGroundColor {
            self.backgroundColor = bgColor
        }
        
        titleLabel.text = notification.messageTitle
        titleLabel.font = notification.messageTitleFont
        if let titleColor = notification.messageTitleColor {
            titleLabel.textColor = titleColor
        }
        messageLabel.text = notification.messageBody
        messageLabel.font = notification.messageBodyFont
        if let bodyColor = notification.messageBodyColor {
            messageLabel.textColor = bodyColor
        }
        
        if let closeButtonColor = notification.closeButtonColor{
            closeButton.setTitleColor(closeButtonColor, for: .normal)
        }
        
        
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        addSubview(closeButton)
    }
    
    internal func setupForImageTextButton() {
        addSubview(titleLabel)
        addSubview(messageLabel)
        imageView.allEdges(to: self, excluding: .bottom)
        titleLabel.topToBottom(of: imageView, offset: 10.0)
        messageLabel.topToBottom(of: titleLabel, offset: 8.0)
        messageLabel.bottom(to: self, offset: -10.0)
        titleLabel.centerX(to: self)
        messageLabel.centerX(to: self)
    }
    
    internal func setupForNps() {
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(npsView)
        
        imageView.allEdges(to: self, excluding: .bottom)
        titleLabel.topToBottom(of: imageView, offset: 10.0)
        messageLabel.topToBottom(of: titleLabel, offset: 8.0)
        npsView.topToBottom(of: messageLabel, offset: 10.0)
        npsView.bottom(to: self, offset: -10.0)
        titleLabel.centerX(to: self)
        messageLabel.centerX(to: self)
        npsView.centerX(to: self)
    }
    
    internal func setupForSmileRating() {
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(sliderStepRating)
        
        imageView.allEdges(to: self, excluding: .bottom)
        titleLabel.topToBottom(of: imageView, offset: 10.0)
        messageLabel.topToBottom(of: titleLabel, offset: 8.0)
        sliderStepRating.topToBottom(of: messageLabel, offset: 10.0)
        sliderStepRating.bottom(to: self, offset: -30.0)
        
        titleLabel.centerX(to: self)
        messageLabel.centerX(to: self)
        sliderStepRating.centerX(to: self)
        
        sliderStepRating.leading(to: self, offset: 20.0)
        sliderStepRating.trailing(to: self, offset: -20.0)
    }
    
    internal func setupForEmailForm() {
        imageView.removeFromSuperview()
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(emailTF)
        addSubview(termsButton)
        addSubview(checkbox)
        addSubview(self.resultLabel)
        
        resultLabel.isHidden = true
        messageLabel.textAlignment = .natural
        titleLabel.top(to: self, offset: 50)
        messageLabel.topToBottom(of: titleLabel, offset: 10)
        emailTF.topToBottom(of: messageLabel, offset: 20)
        checkbox.topToBottom(of: emailTF, offset: 20)
        termsButton.centerY(to: checkbox)
        resultLabel.topToBottom(of: checkbox, offset: 10.0)
        checkbox.bottom(to: self, offset: -80)
        
        checkbox.size(CGSize(width: 20, height: 20))
        
        checkbox.leading(to: self, offset: 20)
        termsButton.leadingToTrailing(of: checkbox, offset: 10)
        termsButton.trailing(to: self, offset: -12)
        titleLabel.leading(to: self, offset: 20)
        messageLabel.leading(to: titleLabel)
        messageLabel.trailing(to: self, offset: -20)
        emailTF.leading(to: self, offset: 20)
        emailTF.trailing(to: self, offset: -20.0)
        resultLabel.leading(to: self.checkbox)
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.addGestureRecognizer(tapGesture)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    internal func setupForDefault() {
        addSubview(titleLabel)
        addSubview(messageLabel)
        
        imageView.allEdges(to: self, excluding: .bottom)
        titleLabel.topToBottom(of: imageView, offset: 8.0)
        messageLabel.topToBottom(of: titleLabel, offset: 8.0)
        messageLabel.bottom(to: self, offset: -10.0)
    }
}
