# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

target 'WanderMint' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for WanderMint
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Functions'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1'
      
      # Fix for gRPC-Core compilation issues
      if target.name == 'gRPC-Core'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'GRPC_CRONET_WITH_PACKET_COALESCING=0'
        config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'NO'
      end
    end
  end
end