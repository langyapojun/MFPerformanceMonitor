Pod::Spec.new do |s|
  s.name             = "MFPerformanceMonitor"
  s.version          = "0.2.3"
  s.homepage         = "https://github.com/vviicc/MFPerformanceMonitor"
  s.summary          = "A tool to monitor ios app performance such as memory and cpu."

  s.license          = 'MIT'
  s.author           = { "Vic" => "704550191@qq.com" }
  s.source           = { :git => "https://github.com/vviicc/MFPerformanceMonitor.git", :tag => s.version }

  s.ios.deployment_target = '7.0'
  #s.framework = 'LibXL'
  s.preserve_path = 'thirdParty/LibXL.framework'
  s.vendored_frameworks = 'thirdParty/LibXL.framework'

  s.source_files = '**/*.{h,m}'
  s.resources = ["resources/*.png"]

  s.public_header_files = '*.{h}'
  s.requires_arc = true
  s.dependency 'PNChart'
  s.dependency 'ZipArchiveV'
  s.dependency 'MLeaksFinder'

  the_ldflags    = '$(inherited) -lz -lstdc++ -framework "LibXL"'

  s.xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '"$(PODS_ROOT)/MFPerformanceMonitor/thirdParty/"',
    'OTHER_LDFLAGS'  => the_ldflags
  }
end

