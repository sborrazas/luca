require './app'

assets_path = Dir.pwd + '/vendor/assets'
javascript_path = File.join( assets_path, 'javascripts' )
stylesheets_path = File.join( assets_path, 'stylesheets' )

guard 'sprockets2', :assets_path => assets_path, :sprockets => App.sprockets, :precompile=>[/^luca-ui.(coffee|js|css|scss)$/], :digest => false, :gz => false do
  watch(%r{^src/.+$})

  callback(:run_on_change_end) do
    compiled = Dir.glob( assets_path + '/luca-ui*.*s' )
    
    compiled.each do |file|
      if File.extname(file) == ".js"
        FileUtils.mkdir_p javascript_path
        FileUtils.mv file, javascript_path
      end

      if File.extname(file) == ".css"
        FileUtils.mkdir_p stylesheets_path
        FileUtils.mv file, stylesheets_path
      end
    end
  end
end