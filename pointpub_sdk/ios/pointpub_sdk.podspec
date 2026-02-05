#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint pointpub_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pointpub_sdk'
  s.version          = '1.0.2'
  s.summary          = 'PointPub plugin for Flutter'
  s.description      = <<-DESC
"A Flutter OfferWall SDK for Android and iOS that enables apps to show reward-based campaigns and manage virtual points through a unified cross-platform API."
                       DESC
  s.homepage         = 'https://github.com/adxcorp/pointpub-flutter-sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = "Neptune Company"
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'pointpub-ios','2.0.3'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'pointpub_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
