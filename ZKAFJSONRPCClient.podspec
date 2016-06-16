Pod::Spec.new do |s|
  s.name         = "ZKAFJSONRPCClient"
  s.version      = "1.0.2"
  s.summary      = "jsonrpc方式与服务端交互 配合3.0版本 AFNetworking."
  s.homepage     = "https://github.com/zhengkai85/ZKAFJSONRPCClient"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "zhengkai" => "83794521@qq.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/zhengkai85/ZKAFJSONRPCClient.git", :tag => "1.0.2" }
  s.source_files = "ZKAFJSONRPCClient/*"  
  s.dependency "AFNetworking", "~> 3.1.0"
  s.requires_arc = true
end
