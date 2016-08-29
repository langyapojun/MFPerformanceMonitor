Pod::Spec.new do |s|
  s.name             = "MFPerformanceMonitor"
  s.version          = "0.1.4"
  s.summary          = "A tool to monitor ios app performance such as memory and cpu."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

#  s.description      = <<-DESC
#TODO: Add long description of the pod here.
#                       DESC

  s.homepage         = "https://github.com/vviicc/MFPerformanceMonitor"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Vic" => "704550191@qq.com" }
  s.source           = { :git => "https://github.com/vviicc/MFPerformanceMonitor.git", :tag => s.version }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '7.0'
  #s.framework = 'LibXL'
  s.vendored_frameworks = 'thirdParty/LibXL.framework'

  s.source_files = '**/*.{h,m}'

  s.public_header_files = '**/*.{h}'
  s.requires_arc = true
  s.dependency 'PNChart'
end

