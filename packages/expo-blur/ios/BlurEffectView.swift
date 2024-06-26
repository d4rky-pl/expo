// Copyright 2015-present 650 Industries. All rights reserved.

import UIKit
import ExpoModulesCore

/**
 This class is based on https://gist.github.com/darrarski/29a2a4515508e385c90b3ffe6f975df7
 */
final class BlurEffectView: UIVisualEffectView {
  @Clamping(lowerBound: 0.01, upperBound: 1)
  var intensity: Double = 0.5 {
    didSet {
      setNeedsDisplay()
    }
  }

  var tint: TintStyle = .light {
    didSet {
      visualEffect = UIBlurEffect(style: tint.toBlurEffect())
    }
  }

  private var visualEffect: UIVisualEffect = UIBlurEffect(style: TintStyle.default.toBlurEffect()) {
    didSet {
      setNeedsDisplay()
    }
  }
  private var animator: UIViewPropertyAnimator?

  init() {
    super.init(effect: nil)
  }

  required init?(coder aDecoder: NSCoder) { nil }

  deinit {
    animator?.stopAnimation(true)
  }

  override func draw(_ rect: CGRect) {
    super.draw(rect)

    // BlurView intensity relies on running an animation and making it partially complete. This means that there
    // is a continually running animation, which makes detox hang (it waits for the animation to finish indefinitely).
    // We can detect if detoxServer is running and in that case replace smooth intensity value with an on/off behaviour.
    if isDetoxPresent() {
      effect = intensity > 0 ? visualEffect : nil
      return
    }

    effect = nil
    animator?.stopAnimation(true)
    animator = UIViewPropertyAnimator(duration: 1, curve: .linear) { [unowned self] in
      self.effect = visualEffect
    }
    animator?.fractionComplete = CGFloat(intensity)
  }
}

private func isDetoxPresent() -> Bool {
  let args = ProcessInfo.processInfo.arguments

  return args.contains("-detoxServer") && args.contains("-detoxSessionId")
}

/**
 Property wrapper clamping the value between an upper and lower bound
 */
@propertyWrapper
struct Clamping<Value: Comparable> {
  var wrappedValue: Value

  init(wrappedValue: Value, lowerBound: Value, upperBound: Value) {
    self.wrappedValue = max(lowerBound, min(upperBound, wrappedValue))
  }
}
