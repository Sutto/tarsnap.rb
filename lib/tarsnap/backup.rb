class Tarsnap::Backup

  DATE_FORMAT   = "%Y%m%d"
  FORMAT_REGEXP = /\d{4}\d{2}\d{2}/
  
  DEFAULTS = {
    :daily   => 7,
    :weekly  => 3,
    :monthly => 6
  }
  
  def initialize(name, options = {})
    @name    = name
    @options = DEFAULTS.merge(options)
    @chdir   = options.delete(:cd)
    @paths   = []
  end
  
  def add_archive(name)
    @paths << "@#{name}"
  end
  
  def add_path(path)
    @paths << path.to_s
  end
  
  def create!(date = Time.now)
    archive_name = "#{@name}-#{date.utc.strftime(FORMAT_REGEXP)}"
    args = generate_files
    options = {}
    options[:C] = @chdir if !@chdir.to_s.strip.empty?
    args << options
    Tarsnap.create!(archive_name, *args)
  end
  
  def archives
    Tarsnap.list.grep(/^#{Regexp.escape(@name)}\-#{FORMAT_REGEXP}$/)
  end
  
  protected
  
  def generate_files
    @paths.map { |f| f.to_s }
  end
  
end