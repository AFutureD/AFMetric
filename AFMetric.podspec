#
# Be sure to run `pod lib lint AFMetric.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AFMetric'
  s.version          = '0.1.0'
  s.summary          = 'A short description of AFMetric.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/ninuo.dong/AFMetric'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ninuo.dong' => 'ninuo.dong@tuya.com' }
  s.source           = { :git => 'https://github.com/ninuo.dong/AFMetric.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'AFMetric/Classes/**/*'
  
  # s.resource_bundles = {
  #   'AFMetric' => ['AFMetric/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'YYModel'

  s.define_singleton_method :support_xcode12_config do
    pod_xcconfig = attributes_hash.fetch('pod_target_xcconfig', {})

    all_archs = %w[arm64 armv7 x86_64 i386]
    exclude_archs = all_archs - pod_xcconfig.fetch('VALID_ARCHS', all_archs.join(' ')).split(' ')

    pod_xcconfig['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    pod_xcconfig['EXCLUDED_ARCHS[sdk=watchsimulator*]'] = 'x86_64 arm64'
    unless exclude_archs.empty?
     pod_xcconfig['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] += ' ' + exclude_archs.join(' ')
    end

    pod_xcconfig.delete('VALID_ARCHS')
    attributes_hash['pod_target_xcconfig'] = pod_xcconfig

    user_xcconfig = attributes_hash.fetch('user_target_xcconfig', {})
    user_xcconfig['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    user_xcconfig['EXCLUDED_ARCHS[sdk=watchsimulator*]'] = 'x86_64 arm64'
    attributes_hash['user_target_xcconfig'] = user_xcconfig
  end
end
