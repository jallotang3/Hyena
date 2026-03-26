Pod::Spec.new do |s|
  s.name             = 'HyenaCore'
  s.version          = '0.1.0'
  s.summary          = 'HyenaCore gomobile xcframework'
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'Hyena' => 'dev@example.com' }
  s.platform         = :ios, '13.0'
  s.source           = { :path => '.' }
  s.vendored_frameworks = 'HyenaCore.xcframework'
end
