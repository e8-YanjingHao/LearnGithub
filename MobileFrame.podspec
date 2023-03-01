Pod::Spec.new do |spec|
  spec.name             = 'MobileFrame'
  spec.version          = '22.10.000'
  spec.license          = { :type => 'MIT' }
  spec.homepage         = 'https://encompasstech.com/SwiftKickMobile/MobileFrame'
  spec.authors          = { "Encompass" => "encompass@encompass8.cn" }
  spec.summary          = 'A basic frame work of encompass mobile.'
  spec.source           = {:svn => 'https://svn.encompass8.com:8443/svn/EM-Client/MobileFrame/iOS/Dev/'}
  spec.platform         = :ios, '11.0'
  spec.swift_version    = '5.0'
  spec.ios.deployment_target = '11.0'
  spec.requires_arc     = true
  spec.default_subspec  = 'App'

  spec.subspec 'App' do |app|
      app.source_files = 'MobileFrame/**/*.swift'
      app.resource_bundles = {'MobileFrame' => ['MobileFrame/Resources/*.*']}

      app.dependency 'SSZipArchive', '~> 2.4.2'
      app.dependency 'SwiftyJSON', '~> 5.0.1'
      app.dependency 'SQLite.swift', '~> 0.13.0'
      app.dependency 'ReachabilitySwift', '~> 5.0.0'
      app.dependency 'SnapKit', '~> 5.0.1'
      app.dependency 'Alamofire', '~> 5.4.4'
      
  end
end
