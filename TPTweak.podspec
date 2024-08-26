Pod::Spec.new do |spec|
  spec.name           = "TPTweak"
  spec.version        = "2.0.2"
  spec.summary        = "TPTweak is a debugging tool to help adjust your iOS app on the fly without recompile"

  spec.license        = { :type => "Apache 2.0", :file => "LICENSE.md" }
  spec.author         = { "Wendy Liga" => "wendy.liga@tokopedia.com" }
  spec.homepage       = "https://github.com/tokopedia/ios-tptweak"

  spec.platform       = :ios, "11.0"
  spec.swift_versions = ["5.4"]
  spec.source         = { :git => "https://github.com/tokopedia/ios-tptweak.git", :tag => "#{spec.version}" }
  spec.default_subspecs = "Core"

  spec.subspec 'Core' do |sp|
    sp.source_files   = "Sources/TPTweak/**/*.swift"
    sp.exclude_files  = "Sources/TPTweak/TPTweakStore+DevTools.swift"
  end

  spec.subspec 'DevTools' do |sp|
    sp.compiler_flags = '-DUSE_DEVTOOLS'
    sp.source_files   = "Sources/TPTweak/**/*.swift"
    sp.exclude_files  = "Sources/TPTweak/TPTweakStore+Live.swift"
  end
end
