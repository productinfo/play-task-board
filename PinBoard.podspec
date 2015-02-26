#
# Be sure to run `pod lib lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = "PinBoard"
  s.version          = '0.1.5'
  s.summary          = "A pin board using various ShinobiEssentials components"
  s.description      = <<-DESC
                       A pin board which uses SEssentialsFlowLayout and other Essentials components.
                       DESC
  s.homepage         = "http://www.shinobicontrols.com"
  s.license          = 'Apache License, Version 2.0'
  s.author           = { "Alison Clarke" => "aclarke@shinobicontrols.com" }
  s.source           = { :git => "https://bitbucket.org/shinobicontrols/play-pin-board.git", 
                         :tag => s.version.to_s,
                         :submodules => true 
                       }
  s.social_media_url = 'https://twitter.com/shinobicontrols'
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'PinBoard/PinBoard/**/*.{h,m}'
  s.dependency 'ShinobiPlayUtils'
  s.resources = ['PinBoard/**/PinBoardTasks.plist', 'PinBoard/**/PinBoard.storyboard', 'PinBoard/**/*.xcassets']
  s.frameworks = 'QuartzCore', 'ShinobiEssentials'
  s.xcconfig     = { 'FRAMEWORK_SEARCH_PATHS' => '"$(DEVELOPER_FRAMEWORKS_DIR)" "$(PROJECT_DIR)/../"' }
end
