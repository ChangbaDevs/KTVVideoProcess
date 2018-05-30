Pod::Spec.new do |s|
  s.name                = "KTVVideoProcess"
  s.version             = "1.0.0"
  s.summary             = "A High-Performance video effects processing framework."
  s.homepage            = "https://github.com/ChangbaDevs/KTVVideoProcess"
  s.license             = { :type => "MIT", :file => "LICENSE" }
  s.author              = { "Single" => "libobjc@gmail.com" }
  s.social_media_url    = "https://weibo.com/3118550737"
  s.platform            = :ios, "8.0"
  s.source              = { :git => "https://github.com/ChangbaDevs/KTVVideoProcess.git", :tag => "#{s.version}" }
  s.source_files        = "KTVVideoProcess", "KTVVideoProcess/**/*.{h,m}"
  s.public_header_files = "KTVVideoProcess/**/*.h"
  s.frameworks          = "UIKit", "Foundation", "GLKit"
  s.requires_arc        = true
end
