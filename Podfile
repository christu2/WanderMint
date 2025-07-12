# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

target 'WanderMint' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks! :linkage => :static

  # Pods for WanderMint
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Functions'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'

  target 'WanderMintTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1'
      
      # Suppress common warnings for all pods
      config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
      config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'NO'
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      
      # Fix for gRPC and related targets
      if target.name.include?('gRPC') || target.name.include?('grpc') || target.name.include?('abseil') || target.name.include?('zutil')
        config.build_settings['CLANG_WARN_MACRO_REDEFINITION'] = 'NO'
        config.build_settings['GCC_WARN_ABOUT_MISSING_PROTOTYPES'] = 'NO'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1'
      end
      
      # Remove duplicate linker flags
      other_ldflags = config.build_settings['OTHER_LDFLAGS'] || []
      other_ldflags = other_ldflags.uniq if other_ldflags.is_a?(Array)
      config.build_settings['OTHER_LDFLAGS'] = other_ldflags
      
      # Force GoogleUtilities linking
      if target.name.include?('GoogleUtilities')
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
        config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
      end
    end
  end
end