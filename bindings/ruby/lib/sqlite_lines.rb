require "version"

module SqliteLines
  class Error < StandardError; end
  def self.lines_loadable_path
    File.expand_path('../lines0', __FILE__)
  end
  def self.load(db)
    db.load_extension(self.lines_loadable_path)
  end
end
