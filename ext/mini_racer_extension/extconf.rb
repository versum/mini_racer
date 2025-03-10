require 'mkmf'
require_relative '../../lib/mini_racer/version'
gem 'libv8-node', MiniRacer::LIBV8_NODE_VERSION
require 'libv8-node'

Gem.path.each do |gem_home|
  xsystem "test -d #{gem_home}/gems/libv8-node-16.10.0.0-#{RUBY_PLATFORM}/vendor/v8/#{RUBY_PLATFORM}-musl && test ! -d #{gem_home}/gems/libv8-node-16.10.0.0-#{RUBY_PLATFORM}/vendor/v8/#{RUBY_PLATFORM} && ln -s #{gem_home}/gems/libv8-node-16.10.0.0-#{RUBY_PLATFORM}/vendor/v8/#{RUBY_PLATFORM}-musl #{gem_home}/gems/libv8-node-16.10.0.0-#{RUBY_PLATFORM}/vendor/v8/#{RUBY_PLATFORM}"
  xsystem "test -d #{gem_home}/gems/libv8-node-16.10.0.0-#{RUBY_PLATFORM}-musl/vendor/v8/#{RUBY_PLATFORM}-musl && test ! -d #{gem_home}/gems/libv8-node-16.10.0.0-#{RUBY_PLATFORM}-musl/vendor/v8/#{RUBY_PLATFORM} && ln -s #{gem_home}/gems/libv8-node-16.10.0.0-#{RUBY_PLATFORM}-musl/vendor/v8/#{RUBY_PLATFORM}-musl #{gem_home}/gems/libv8-node-16.10.0.0-#{RUBY_PLATFORM}-musl/vendor/v8/#{RUBY_PLATFORM}"
end

IS_DARWIN = RUBY_PLATFORM =~ /darwin/

have_library('pthread')
have_library('objc') if IS_DARWIN
$CXXFLAGS += " -Wall" unless $CXXFLAGS.split.include? "-Wall"
$CXXFLAGS += " -g" unless $CXXFLAGS.split.include? "-g"
$CXXFLAGS += " -rdynamic" unless $CXXFLAGS.split.include? "-rdynamic"
$CXXFLAGS += " -fPIC" unless $CXXFLAGS.split.include? "-rdynamic" or IS_DARWIN
$CXXFLAGS += " -std=c++14"
$CXXFLAGS += " -fpermissive"
#$CXXFLAGS += " -DV8_COMPRESS_POINTERS"
$CXXFLAGS += " -fvisibility=hidden "

# __declspec gets used by clang via ruby 3.x headers...
$CXXFLAGS += " -fms-extensions"

$CXXFLAGS += " -Wno-reserved-user-defined-literal" if IS_DARWIN

if IS_DARWIN
  $LDFLAGS.insert(0, " -stdlib=libc++ ")
else
  $LDFLAGS.insert(0, " -lstdc++ ")
end

# check for missing symbols at link time
# $LDFLAGS += " -Wl,--no-undefined " unless IS_DARWIN
# $LDFLAGS += " -Wl,-undefined,error " if IS_DARWIN

if ENV['CXX']
  puts "SETTING CXX"
  CONFIG['CXX'] = ENV['CXX']
end

CXX11_TEST = <<EOS
#if __cplusplus <= 199711L
#   error A compiler that supports at least C++11 is required in order to compile this project.
#endif
EOS

`echo "#{CXX11_TEST}" | #{CONFIG['CXX']} -std=c++0x -x c++ -E -`
unless $?.success?
  warn <<EOS


WARNING: C++11 support is required for compiling mini_racer. Please make sure
you are using a compiler that supports at least C++11. Examples of such
compilers are GCC 4.7+ and Clang 3.2+.

If you are using Travis, consider either migrating your build to Ubuntu Trusty or
installing GCC 4.8. See mini_racer's README.md for more information.


EOS
end

CONFIG['LDSHARED'] = '$(CXX) -shared' unless IS_DARWIN
if CONFIG['warnflags']
  CONFIG['warnflags'].gsub!('-Wdeclaration-after-statement', '')
  CONFIG['warnflags'].gsub!('-Wimplicit-function-declaration', '')
end

if enable_config('debug') || enable_config('asan')
  CONFIG['debugflags'] << ' -ggdb3 -O0'
end

Libv8::Node.configure_makefile

if enable_config('asan')
  $CXXFLAGS.insert(0, " -fsanitize=address ")
  $LDFLAGS.insert(0, " -fsanitize=address ")
end

create_makefile 'mini_racer_extension'
