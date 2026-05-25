Pod::Spec.new do |s|
  s.name             = 'multi_pay'
  s.version          = '1.0.0'
  s.summary          = 'Flutter聚合支付插件，支持支付宝、微信、银联云闪付'
  s.description      = 'Flutter聚合支付插件，支持支付宝、微信、银联云闪付'
  s.homepage         = 'https://github.com/example/multi_pay'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Author' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.dependency 'WechatOpenSDK', '~> 2.0.5'

  s.vendored_frameworks = 'Frameworks/UPPaymentControlMini.xcframework', 'Frameworks/AlipaySDK.xcframework'
  s.resources = 'Frameworks/AlipaySDK.bundle'

  s.static_framework = true
  s.frameworks = 'UIKit', 'Foundation', 'CFNetwork', 'SystemConfiguration', 'QuartzCore', 'CoreGraphics', 'CoreMotion', 'CoreTelephony', 'CoreText', 'WebKit'
  s.libraries = 'c++', 'z'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_LDFLAGS' => '-framework CoreTelephony -framework UIKit -framework Foundation -framework CFNetwork -framework SystemConfiguration -framework QuartzCore -framework CoreGraphics -framework CoreMotion -framework CoreText -framework WebKit -lz -lc++',
  }
end
