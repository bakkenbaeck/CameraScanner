Pod::Spec.new do |s|
  s.name             = "CameraScanner"
  s.summary          = "A simple framework to display a camera scanner."
  s.version          = "0.1.0"
  s.homepage         = "https://github.com/bakkenbaeck/CameraScanner"
  s.license          = 'MIT'
  s.author           = { "Bakken & Bæck" => "post@bakkenbaeck.no" }
  s.source           = { :git => "https://github.com/bakkenbaeck/CameraScanner.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/bakkenbaeck'
  s.ios.deployment_target = '10.0'
  s.requires_arc = true
  s.source_files = 'Sources/**/*'
  s.frameworks = 'UIKit'
end
