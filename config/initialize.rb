module SimpleApp

  def self.require_all(dirs)
    begin
      dirs.each do |dir|
        self.class_eval do
          require_relative '.' << dir
        end
      end
    rescue LoadError => ex
      p ex
    end
  end

  require_all(Dir["./lib/**/*.rb"])
  require_all(Dir["./app/**/*.rb"])
end