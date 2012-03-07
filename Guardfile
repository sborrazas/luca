require './app'

assets_path = Dir.pwd + '/vendor/assets'
javascript_path = File.join( assets_path, 'javascripts' )
stylesheets_path = File.join( assets_path, 'stylesheets' )

unless ENV['TEST_MODE']
  guard 'sprockets2', :clean=>false, :assets_path => assets_path, :sprockets => App.sprockets, :precompile=>[/^luca-ui.+(coffee|js|css|scss)$/], :digest => false, :gz => false do
    watch(%r{^src/.+$})
    watch(%r{^spec/.+$})
  end
end

guard 'jasmine' do
  watch(%r{src/(.+)\.coffee}) {|m| "spec/#{ m[1] }_spec.coffee" }
  watch(%r{spec/(.+)_spec\.coffee})
end
