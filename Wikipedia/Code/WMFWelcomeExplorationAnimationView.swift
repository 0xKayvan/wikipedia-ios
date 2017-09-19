import Foundation

open class WMFWelcomeExplorationAnimationView : WMFWelcomeAnimationView {

    lazy var tubeImgView: UIImageView = {
        let tubeRotationPoint = CGPoint(x: 0.576, y: 0.38)
        let initialTubeRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(0.0)
        let rectCorrectingForRotation = CGRect(
            x: bounds.origin.x - (bounds.size.width * (0.5 - tubeRotationPoint.x)),
            y: bounds.origin.y - (bounds.size.height * (0.5 - tubeRotationPoint.y)),
            width: bounds.size.width,
            height: bounds.size.height
        )
        let imgView = UIImageView(frame: rectCorrectingForRotation)
        imgView.image = UIImage(named: "ftux-telescope-tube")
        imgView.contentMode = UIViewContentMode.scaleAspectFit
        imgView.layer.zPosition = 101
        imgView.layer.transform = initialTubeRotationTransform
        imgView.layer.anchorPoint = tubeRotationPoint
        return imgView
    }()

    lazy var baseImgView: UIImageView = {
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "ftux-telescope-base")
        imgView.contentMode = UIViewContentMode.scaleAspectFit
        imgView.layer.zPosition = 101
        imgView.layer.transform = CATransform3DIdentity
        return imgView
    }()

    lazy var dashedCircle: WelcomeCircleShapeLayer = {
        return WelcomeCircleShapeLayer(
            unitRadius: 0.304,
            unitOrigin: CGPoint(x: 0.521, y: 0.531),
            referenceSize: frame.size,
            isDashed: true,
            transform: wmf_scaleZeroTransform,
            opacity:0.0
        )
    }()
    
    lazy var solidCircle: WelcomeCircleShapeLayer = {
        return WelcomeCircleShapeLayer(
            unitRadius: 0.32,
            unitOrigin: CGPoint(x: 0.625, y: 0.55),
            referenceSize: frame.size,
            isDashed: false,
            transform: wmf_scaleZeroTransform,
            opacity:0.0
        )
    }()
    
    lazy var plus1: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPoint(x: 0.033, y: 0.219),
            unitWidth: 0.05,
            referenceSize: frame.size,
            transform: wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var plus2: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPoint(x: 0.11, y: 0.16),
            unitWidth: 0.05,
            referenceSize: frame.size,
            transform: wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line1: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.91, y: 0.778),
            unitWidth: 0.144,
            referenceSize: frame.size,
            transform: wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line2: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.836, y: 0.81),
            unitWidth: 0.06,
            referenceSize: frame.size,
            transform: wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line3: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.907, y: 0.81),
            unitWidth: 0.0125,
            referenceSize: frame.size,
            transform: wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
    }()
    
    override open func addAnimationElementsScaledToCurrentFrameSize(){
        removeExistingSubviewsAndSublayers()

        addSubview(baseImgView)
        addSubview(tubeImgView)
        
        _ = [
            solidCircle,
            dashedCircle,
            plus1,
            plus2,
            line1,
            line2,
            line3
            ].map({ (layer: CALayer) -> () in
                self.layer.addSublayer(layer)
            })
    }
    
    override open func beginAnimations() {
        CATransaction.begin()
        
        let tubeOvershootRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(15.0)
        let tubeFinalRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(-2.0)

        tubeImgView.layer.wmf_animateToOpacity(1.0,
            transform:tubeOvershootRotationTransform,
            delay: 0.8,
            duration: 0.9
        )

        tubeImgView.layer.wmf_animateToOpacity(1.0,
            transform:tubeFinalRotationTransform,
            delay: 1.8,
            duration: 0.9
        )

        solidCircle.wmf_animateToOpacity(0.09,
            transform: CATransform3DIdentity,
            delay: 0.3,
            duration: 1.0
        )

        let animate = { (layer: CALayer) -> () in
            layer.wmf_animateToOpacity(0.15,
                transform: CATransform3DIdentity,
                delay: 0.3,
                duration: 1.0
            )
        }
        
        _ = [
            dashedCircle,
            plus1,
            plus2,
            line1,
            line2,
            line3
            ].map(animate)
        
        CATransaction.commit()
    }
}
