platform :ios, '7.1'

pod 'SVProgressHUD'
pod 'RestKit', '~> 0.20.0'
pod 'JSQMessagesViewController', '~>5.0.4'
pod 'StaticDataTableViewController', '~>0.0.1'

# Remove 64-bit build architecture from Pods targets
post_install do |installer|
  installer.project.targets.each do |target|
    target.build_configurations.each do |configuration|
      target.build_settings(configuration.name)['ARCHS'] = '$(ARCHS_STANDARD_32_BIT)'
    end
  end
end
