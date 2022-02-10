//
//  VisilabsCarouselNotificationViewController.swift
//  VisilabsIOS
//
//  Created by Said Alır on 30.03.2021.
//

import UIKit

public typealias ImageCompletion = (UIImage?, VisilabsCarouselItem) -> Void
public typealias FetchImageBlock = (@escaping ImageCompletion) -> Void

public struct VisilabsCarouselItemBlock {
    public var fetchImageBlock: FetchImageBlock
    public var visilabsCarouselItemView: VisilabsCarouselItemView
    
    public init(fetchImageBlock: @escaping FetchImageBlock, visilabsCarouselItemView: VisilabsCarouselItemView) {
        self.fetchImageBlock = fetchImageBlock
        self.visilabsCarouselItemView = visilabsCarouselItemView
    }
}

typealias Duration = TimeInterval


public protocol DisplaceableView {
    
    var image: UIImage? { get }
    var bounds: CGRect { get }
    var center: CGPoint { get }
    var boundsCenter: CGPoint { get }
    var contentMode: UIView.ContentMode { get }
    var isHidden: Bool { get set }
    
    func convert(_ point: CGPoint, to view: UIView?) -> CGPoint
}

public protocol GalleryDisplacedViewsDataSource: AnyObject {
    
    func provideDisplacementItem(atIndex index: Int) -> DisplaceableView?
}

public protocol ItemController: AnyObject {
    
    var index: Int { get }
    var isInitialController: Bool { get set }
    var delegate:                 ItemControllerDelegate? { get set }
    var displacedViewsDataSource: GalleryDisplacedViewsDataSource? { get set }
    
    func fetchImage()
    
    func presentItem(alongsideAnimation: () -> Void, completion: @escaping () -> Void)
    func dismissItem(alongsideAnimation: () -> Void, completion: @escaping () -> Void)
    
    func closeDecorationViews(_ duration: TimeInterval)
}


public protocol ItemControllerDelegate: AnyObject {
    
    ///Represents a generic transitioning progress from 0 to 1 (or reversed) where 0 is no progress and 1 is fully finished transitioning. It's up to the implementing controller to make decisions about how this value is being calculated, based on the nature of transition.
    func itemController(_ controller: ItemController, didSwipeToDismissWithDistanceToEdge distance: CGFloat)
    
    func itemControllerDidFinishSwipeToDismissSuccessfully()
    
    
    func itemControllerWillAppear(_ controller: ItemController)
    func itemControllerWillDisappear(_ controller: ItemController)
    func itemControllerDidAppear(_ controller: ItemController)
}

public protocol GalleryItemsDataSource: AnyObject {
    func itemCount() -> Int
    func provideGalleryItem(_ index: Int) -> VisilabsCarouselItemBlock
}

public class VisilabsCarouselNotificationViewController: VisilabsBasePageViewController, ItemControllerDelegate {
    
    // UI
    fileprivate let overlayView = VisilabsBlurView()
    /// A custom view on the top of the gallery with layout using default (or custom) pinning settings for header.
    open var headerView: UIView?
    /// A custom view at the bottom of the gallery with layout using default (or custom) pinning settings for footer.
    open var footerView: UIView?
    fileprivate var closeButton: UIButton? = UIButton.closeButton()
    
    fileprivate weak var initialItemController: ItemController?
    
    // LOCAL STATE
    // represents the current page index, updated when the root view of the view controller representing the page stops animating inside visible bounds and stays on screen.
    public var currentIndex: Int
    // Picks up the initial value from configuration, if provided. Subsequently also works as local state for the setting.
    fileprivate var decorationViewsHidden = false
    fileprivate var isAnimating = false
    fileprivate var initialPresentationDone = false
    
    // DATASOURCE/DELEGATE
    fileprivate let itemsDataSource: GalleryItemsDataSource
    fileprivate let pagingDataSource: GalleryPagingDataSource
    
    // CONFIGURATION
    fileprivate var spineDividerWidth:         Float = 30
    fileprivate var galleryPagingMode = GalleryPagingMode.standard
    fileprivate var headerLayout = HeaderLayout.center(25)
    fileprivate var footerLayout = FooterLayout.center(25)
    fileprivate var closeLayout = ButtonLayout.pinRight(8, 16)
    fileprivate var seeAllCloseLayout = ButtonLayout.pinRight(8, 16)
    fileprivate var statusBarHidden = true
    fileprivate var overlayAccelerationFactor: CGFloat = 1
    fileprivate var rotationDuration = 0.15
    fileprivate var rotationMode = GalleryRotationMode.always
    fileprivate let swipeToDismissFadeOutAccelerationFactor: CGFloat = 6
    fileprivate var decorationViewsFadeDuration = 0.15
    
    /// COMPLETION BLOCKS
    /// If set, the block is executed right after the initial launch animations finish.
    open var launchedCompletion: (() -> Void)?
    /// If set, called every time ANY animation stops in the page controller stops and the viewer passes a page index of the page that is currently on screen
    open var landedPageAtIndexCompletion: ((Int) -> Void)?
    /// If set, launched after all animations finish when the close button is pressed.
    open var closedCompletion:                 (() -> Void)?
    /// If set, launched after all animations finish when the close() method is invoked via public API.
    open var programmaticallyClosedCompletion: (() -> Void)?
    /// If set, launched after all animations finish when the swipe-to-dismiss (applies to all directions and cases) gesture is used.
    open var swipedToDismissCompletion:        (() -> Void)?
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) { fatalError() }
    
    public init(startIndex: Int, itemsDataSource: GalleryItemsDataSource, displacedViewsDataSource: GalleryDisplacedViewsDataSource? = nil, configuration: GalleryConfiguration = [], notification: VisilabsInAppNotification) {
        
        self.currentIndex = startIndex
        self.itemsDataSource = itemsDataSource
        
        ///Only those options relevant to the paging GalleryViewController are explicitly handled here, the rest is handled by ItemViewControllers
        for item in configuration {
            
            switch item {
                
            case .imageDividerWidth(let width):                 spineDividerWidth = Float(width)
            case .pagingMode(let mode):                         galleryPagingMode = mode
            case .headerViewLayout(let layout):                 headerLayout = layout
            case .footerViewLayout(let layout):                 footerLayout = layout
            case .closeLayout(let layout):                      closeLayout = layout
            case .statusBarHidden(let hidden):                  statusBarHidden = hidden
            case .hideDecorationViewsOnLaunch(let hidden):      decorationViewsHidden = hidden
            case .decorationViewsFadeDuration(let duration):    decorationViewsFadeDuration = duration
            case .rotationDuration(let duration):               rotationDuration = duration
            case .rotationMode(let mode):                       rotationMode = mode
            case .overlayColor(let color):                      overlayView.overlayColor = color
            case .overlayBlurStyle(let style):                  overlayView.blurringView.effect = UIBlurEffect(style: style)
            case .overlayBlurOpacity(let opacity):              overlayView.blurTargetOpacity = opacity
            case .overlayColorOpacity(let opacity):             overlayView.colorTargetOpacity = opacity
            case .blurPresentDuration(let duration):            overlayView.blurPresentDuration = duration
            case .blurPresentDelay(let delay):                  overlayView.blurPresentDelay = delay
            case .colorPresentDuration(let duration):           overlayView.colorPresentDuration = duration
            case .colorPresentDelay(let delay):                 overlayView.colorPresentDelay = delay
            case .blurDismissDuration(let duration):            overlayView.blurDismissDuration = duration
            case .blurDismissDelay(let delay):                  overlayView.blurDismissDelay = delay
            case .colorDismissDuration(let duration):           overlayView.colorDismissDuration = duration
            case .colorDismissDelay(let delay):                 overlayView.colorDismissDelay = delay
            case .closeButtonMode(let buttonMode):
                
                switch buttonMode {
                case .builtIn:              break
                case .none: break
                    
                case .custom(_):
                    break
                }
                
            default: break
                
                
            }
        }
        
        pagingDataSource = GalleryPagingDataSource(itemsDataSource: itemsDataSource, displacedViewsDataSource: displacedViewsDataSource, configuration: configuration)
        
        super.init(transitionStyle: UIPageViewController.TransitionStyle.scroll,
                   navigationOrientation: UIPageViewController.NavigationOrientation.horizontal,
                   options: [UIPageViewController.OptionsKey.interPageSpacing : NSNumber(value: spineDividerWidth as Float)])
        
        
        self.notification = notification
        
        pagingDataSource.itemControllerDelegate = self
        
        ///This feels out of place, one would expect even the first presented(paged) item controller to be provided by the paging dataSource but there is nothing we can do as Apple requires the first controller to be set via this "setViewControllers" method.
        let initialController = pagingDataSource.createItemController(startIndex, isInitial: true)
        self.setViewControllers([initialController], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
        
        if let controller = initialController as? ItemController {
            
            initialItemController = controller
        }
        
        ///This less known/used presentation style option allows the contents of parent view controller presenting the gallery to "bleed through" the blurView. Otherwise we would see only black color.
        self.modalPresentationStyle = .overFullScreen
        self.dataSource = pagingDataSource
        
        UIApplication.applicationWindow.windowLevel = (statusBarHidden) ? UIWindow.Level.statusBar + 1 : UIWindow.Level.normal
        
        NotificationCenter.default.addObserver(self, selector: #selector(VisilabsCarouselNotificationViewController.rotate), name: UIDevice.orientationDidChangeNotification, object: nil)
        
    }
    
    
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func configureOverlayView() {
        
        overlayView.bounds.size = UIScreen.main.bounds.insetBy(dx: -UIScreen.main.bounds.width / 2, dy: -UIScreen.main.bounds.height / 2).size
        overlayView.center = CGPoint(x: (UIScreen.main.bounds.width / 2), y: (UIScreen.main.bounds.height / 2))
        
        self.view.addSubview(overlayView)
        self.view.sendSubviewToBack(overlayView)
    }
    
    fileprivate func configureHeaderView() {
        
        if let header = headerView {
            header.alpha = 0
            self.view.addSubview(header)
        }
    }
    
    fileprivate func configureFooterView() {
        if let footer = footerView {
            footer.alpha = 0
            self.view.addSubview(footer)
        }
    }
    
    fileprivate func configureCloseButton() {
        if let closeButton = closeButton {
            closeButton.addTarget(self, action: #selector(VisilabsCarouselNotificationViewController.closeInteractively), for: .touchUpInside)
            closeButton.alpha = 0
            self.view.addSubview(closeButton)
        }
    }
    
    
    
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            if (statusBarHidden || UIScreen.hasNotch) {
                additionalSafeAreaInsets = UIEdgeInsets(top: -20, left: 0, bottom: 0, right: 0)
            }
        }
        
        configureHeaderView()
        configureFooterView()
        configureCloseButton()
        
        self.view.clipsToBounds = false
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard initialPresentationDone == false else { return }
        
        ///We have to call this here (not sooner), because it adds the overlay view to the presenting controller and the presentingController property is set only at this moment in the VC lifecycle.
        configureOverlayView()
        
        ///The initial presentation animations and transitions
        presentInitially()
        
        initialPresentationDone = true
    }
    
    fileprivate func presentInitially() {
        
        isAnimating = true
        
        ///Animates decoration views to the initial state if they are set to be visible on launch. We do not need to do anything if they are set to be hidden because they are already set up as hidden by default. Unhiding them for the launch is part of chosen UX.
        initialItemController?.presentItem(alongsideAnimation: { [weak self] in
            
            self?.overlayView.present()
            
        }, completion: { [weak self] in
            
            if let strongSelf = self {
                
                if strongSelf.decorationViewsHidden == false {
                    
                    strongSelf.animateDecorationViews(visible: true)
                }
                
                strongSelf.isAnimating = false
                
                strongSelf.launchedCompletion?()
            }
        })
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if rotationMode == .always && UIApplication.isPortraitOnly {
            
            let transform = windowRotationTransform()
            let bounds = rotationAdjustedBounds()
            
            self.view.transform = transform
            self.view.bounds = bounds
        }
        
        overlayView.frame = view.bounds.insetBy(dx: -UIScreen.main.bounds.width * 2, dy: -UIScreen.main.bounds.height * 2)
        
        layoutButton(closeButton, layout: closeLayout)
        layoutHeaderView()
        layoutFooterView()
    }
    
    private var defaultInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return UIEdgeInsets(top: statusBarHidden ? 0.0 : 20.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
    
    fileprivate func layoutButton(_ button: UIButton?, layout: ButtonLayout) {
        
        guard let button = button else { return }
        
        switch layout {
            
        case .pinRight(let marginTop, let marginRight):
            
            button.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
            button.frame.origin.x = self.view.bounds.size.width - marginRight - button.bounds.size.width
            button.frame.origin.y = defaultInsets.top + marginTop
            
        case .pinLeft(let marginTop, let marginLeft):
            
            button.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
            button.frame.origin.x = marginLeft
            button.frame.origin.y = defaultInsets.top + marginTop
        }
    }
    
    fileprivate func layoutHeaderView() {
        
        guard let header = headerView else { return }
        
        switch headerLayout {
            
        case .center(let marginTop):
            
            header.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
            header.center = self.view.boundsCenter
            header.frame.origin.y = defaultInsets.top + marginTop
            
        case .pinBoth(let marginTop, let marginLeft,let marginRight):
            
            header.autoresizingMask = [.flexibleBottomMargin, .flexibleWidth]
            header.bounds.size.width = self.view.bounds.width - marginLeft - marginRight
            header.sizeToFit()
            header.frame.origin = CGPoint(x: marginLeft, y: defaultInsets.top + marginTop)
            
        case .pinLeft(let marginTop, let marginLeft):
            
            header.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
            header.frame.origin = CGPoint(x: marginLeft, y: defaultInsets.top + marginTop)
            
        case .pinRight(let marginTop, let marginRight):
            
            header.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
            header.frame.origin = CGPoint(x: self.view.bounds.width - marginRight - header.bounds.width, y: defaultInsets.top + marginTop)
        }
    }
    
    fileprivate func layoutFooterView() {
        
        guard let footer = footerView else { return }
        
        switch footerLayout {
            
        case .center(let marginBottom):
            
            footer.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
            footer.center = self.view.boundsCenter
            footer.frame.origin.y = self.view.bounds.height - footer.bounds.height - marginBottom - defaultInsets.bottom
            
        case .pinBoth(let marginBottom, let marginLeft,let marginRight):
            
            footer.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
            footer.frame.size.width = self.view.bounds.width - marginLeft - marginRight
            footer.sizeToFit()
            footer.frame.origin = CGPoint(x: marginLeft, y: self.view.bounds.height - footer.bounds.height - marginBottom - defaultInsets.bottom)
            
        case .pinLeft(let marginBottom, let marginLeft):
            
            footer.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
            footer.frame.origin = CGPoint(x: marginLeft, y: self.view.bounds.height - footer.bounds.height - marginBottom - defaultInsets.bottom)
            
        case .pinRight(let marginBottom, let marginRight):
            
            footer.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
            footer.frame.origin = CGPoint(x: self.view.bounds.width - marginRight - footer.bounds.width, y: self.view.bounds.height - footer.bounds.height - marginBottom - defaultInsets.bottom)
        }
    }
    
    
    open func page(toIndex index: Int) {
        
        guard currentIndex != index && index >= 0 && index < self.itemsDataSource.itemCount() else { return }
        
        let imageViewController = self.pagingDataSource.createItemController(index)
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        
        // workaround to make UIPageViewController happy
        if direction == .forward {
            let previousVC = self.pagingDataSource.createItemController(index - 1)
            setViewControllers([previousVC], direction: direction, animated: true, completion: { finished in
                DispatchQueue.main.async(execute: { [weak self] in
                    self?.setViewControllers([imageViewController], direction: direction, animated: false, completion: nil)
                })
            })
        } else {
            let nextVC = self.pagingDataSource.createItemController(index + 1)
            setViewControllers([nextVC], direction: direction, animated: true, completion: { finished in
                DispatchQueue.main.async(execute: { [weak self] in
                    self?.setViewControllers([imageViewController], direction: direction, animated: false, completion: nil)
                })
            })
        }
    }
    
    func removePage(atIndex index: Int, completion: @escaping () -> Void) {
        
        // If removing last item, go back, otherwise, go forward
        
        let direction: UIPageViewController.NavigationDirection = index < self.itemsDataSource.itemCount() ? .forward : .reverse
        
        let newIndex = direction == .forward ? index : index - 1
        
        if newIndex < 0 { close(); return }
        
        let vc = self.pagingDataSource.createItemController(newIndex)
        setViewControllers([vc], direction: direction, animated: true) { _ in completion() }
    }
    
    open func reload(atIndex index: Int) {
        
        guard index >= 0 && index < self.itemsDataSource.itemCount() else { return }
        
        guard let firstVC = viewControllers?.first, let itemController = firstVC as? ItemController else { return }
        
        itemController.fetchImage()
    }
    
    // MARK: - Animations
    
    @objc fileprivate func rotate() {
        
        /// If the app supports rotation on global level, we don't need to rotate here manually because the rotation
        /// of key Window will rotate all app's content with it via affine transform and from the perspective of the
        /// gallery it is just a simple relayout. Allowing access to remaining code only makes sense if the app is
        /// portrait only but we still want to support rotation inside the gallery.
        guard UIApplication.isPortraitOnly else { return }
        
        guard UIDevice.current.orientation.isFlat == false &&
                isAnimating == false else { return }
        
        isAnimating = true
        
        UIView.animate(withDuration: rotationDuration, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: { [weak self] () -> Void in
            
            self?.view.transform = windowRotationTransform()
            self?.view.bounds = rotationAdjustedBounds()
            self?.view.setNeedsLayout()
            
            self?.view.layoutIfNeeded()
            
        })
        { [weak self] finished  in
            
            self?.isAnimating = false
        }
    }
    
    /// Invoked when closed programmatically
    open func close() {
        
        closeDecorationViews(programmaticallyClosedCompletion)
    }
    
    /// Invoked when closed via close button
    @objc fileprivate func closeInteractively() {
        
        closeDecorationViews(closedCompletion)
    }
    
    fileprivate func closeDecorationViews(_ completion: (() -> Void)?) {
        
        guard isAnimating == false else { return }
        isAnimating = true
        
        if let itemController = self.viewControllers?.first as? ItemController {
            
            itemController.closeDecorationViews(decorationViewsFadeDuration)
        }
        
        UIView.animate(withDuration: decorationViewsFadeDuration, animations: { [weak self] in
            
            self?.headerView?.alpha = 0.0
            self?.footerView?.alpha = 0.0
            self?.closeButton?.alpha = 0.0
            
        }, completion: { [weak self] done in
            
            if let strongSelf = self,
               let itemController = strongSelf.viewControllers?.first as? ItemController {
                
                itemController.dismissItem(alongsideAnimation: {
                    
                    strongSelf.overlayView.dismiss()
                    
                }, completion: { [weak self] in
                    
                    self?.isAnimating = true
                    self?.closeGallery(false, completion: completion)
                })
            }
        })
    }
    
    func closeGallery(_ animated: Bool, completion: (() -> Void)?) {
        
        self.overlayView.removeFromSuperview()
        
        self.modalTransitionStyle = .crossDissolve
        
        self.dismiss(animated: animated) {
            
            UIApplication.applicationWindow.windowLevel = UIWindow.Level.normal
            completion?()
        }
    }
    
    fileprivate func animateDecorationViews(visible: Bool) {
        
        let targetAlpha: CGFloat = (visible) ? 1 : 0
        
        UIView.animate(withDuration: decorationViewsFadeDuration, animations: { [weak self] in
            
            self?.headerView?.alpha = targetAlpha
            self?.footerView?.alpha = targetAlpha
            self?.closeButton?.alpha = targetAlpha
            
        })
    }
    
    public func itemControllerWillAppear(_ controller: ItemController) {
        
        
    }
    
    public func itemControllerWillDisappear(_ controller: ItemController) {
        
        
    }
    
    public func itemControllerDidAppear(_ controller: ItemController) {
        
        self.currentIndex = controller.index
        self.landedPageAtIndexCompletion?(self.currentIndex)
        self.headerView?.sizeToFit()
        self.footerView?.sizeToFit()
        
        
    }
    
    
    public func itemController(_ controller: ItemController, didSwipeToDismissWithDistanceToEdge distance: CGFloat) {
        
        if decorationViewsHidden == false {
            
            let alpha = 1 - distance * swipeToDismissFadeOutAccelerationFactor
            
            closeButton?.alpha = alpha
            headerView?.alpha = alpha
            footerView?.alpha = alpha
        }
        
        self.overlayView.blurringView.alpha = 1 - distance
        self.overlayView.colorView.alpha = 1 - distance
    }
    
    public func itemControllerDidFinishSwipeToDismissSuccessfully() {
        
        self.swipedToDismissCompletion?()
        self.overlayView.removeFromSuperview()
        self.dismiss(animated: false, completion: nil)
    }
}

