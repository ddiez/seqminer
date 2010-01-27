spec = Gem::Specification.new do |s| 
  s.name = "SeqMiner"
  s.version = "0.0.1"
  s.author = "Diego Diez"
  s.email = "diego10ruiz@gmail.com"
  s.homepage = "http://"
  s.platform = Gem::Platform::RUBY
  s.summary = "A platform to mine gene families from diverse resources"
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.require_path = "lib"
  s.autorequire = "seqminer"
  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
  #s.add_dependency("dependency", ">= 0.x.x")
end