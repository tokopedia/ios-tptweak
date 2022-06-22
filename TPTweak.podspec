Pod::Spec.new do |spec|
  spec.name         = "TPTweak"
  spec.version      = "1.0.0"
  spec.summary      = "TPTweak is a debugging tool to help adjust your iOS app on the fly without recompile"

  spec.screenshots  = ""
  spec.license      = { :type => "Apache 2.0", :file => "LICENSE.md" }
  spec.author             = { "Wendy Liga" => "wendy.liga@tokopedia.com" }
  
  spec.platform     = :ios
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/tokopedia/ios-tptweak.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/TPTweak/**/*.swift"

end
