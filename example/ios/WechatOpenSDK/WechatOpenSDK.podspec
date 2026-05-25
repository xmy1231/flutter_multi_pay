Pod::Spec.new do |s|
  s.name         = 'WechatOpenSDK'
  s.version      = '2.0.5'
  s.summary      = 'WeChat SDK with arm64 simulator support'
  s.homepage     = 'https://github.com/weixin-open'
  s.license      = { :type => 'MIT' }
  s.author       = { 'WeChat' => 'weixin-open@qq.com' }
  s.source       = { :path => '.' }
  s.platforms    = { :ios => '13.0' }
  s.vendored_libraries = 'OpenSDK2.0.5/libWechatOpenSDK.a'
  s.source_files = 'OpenSDK2.0.5/*.h'
  s.public_header_files = 'OpenSDK2.0.5/*.h'
  s.frameworks   = 'CoreGraphics', 'Security', 'UIKit', 'WebKit'
  s.libraries    = 'c++', 'sqlite3.0', 'z'
end
