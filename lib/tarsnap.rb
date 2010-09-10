require 'pathname'
require 'escape'

class Tarsnap
  
  class << self
    
    attr_accessor :binary_mapping
    
    def prefix
      @prefix = lookup_default_prefix if !defined?(@prefix) || @prefix.to_s.strip.empty?
      Pathname(@prefix)
    end
    
    def prefix=(value)
      @prefix = value
    end
    
    def bin_path(name)
      name = binary_mapping[name] if name.is_a?(Symbol)
      name.include?('/') ? name : prefix.join("bin", name).to_s
    end
    
    def list
      names = []
      status, output = exec!(:tarsnap, "--list-archives")
      output.each_line { |l| names << l.strip } if status
      names
    end

    def delete!(name, options = {})
      status, _ = exec!(:tarsnap, "-d", "-f", name, *hash_to_arguments(options))
      status
    end

    def create!(name, *files)
      options = extract_options(files)
      status, _ = exec!(:tarsnap, "-c", "-f", name, *(hash_to_arguments(options) + files))
      status
    end
    
    protected
    
    def hash_to_arguments(options = {})
      arguments = []
      options.each_pair do |k, v|
        case k.to_s
        when "cd", "C"
          arguments << "-C"
          arguments << v.to_s
        when "cache_dir", "cache-dir"
          arguments << "--cachedir"
          arguments << v.to_s
        when "aggressive_networking", "aggressive-networking"
          arguments << "--#{k ? "" : "no-"}aggressive-networking"
        when "l", "check-links", "check_links"
          arguments << "--check-links"
        when "keyfile", "key_file", "key-file"
          arguments << "--keyfile"
          arguments << v.to_s
        when "dry-run", "dry_run", "dry-run"
          arguments << "--dry-run"
        end
      end
      arguments
    end
    
    def exec!(key, *args)
      binary = bin_path(key)
      command = Escape.shell_command([binary] + args.map { |a| a.to_s }).to_s
      output = `#{command}`
      return $?.success?, output
    end
    
    def lookup_default_prefix
      output = `which tarsnap`.strip
      output.empty? ? '/usr/local' : File.dirname(output).gsub("/bin", "")
    end
    
    def extract_options(array)
      array.last.is_a?(Hash) ? array.pop : {}
    end
    
  end
  
  self.binary_mapping ||= {}
  binary_mapping[:tarsnap]         = "tarsnap"
  binary_mapping[:tarsnap_keygen]  = "tarsnap-keygen"
  binary_mapping[:tarsnap_keymgmt] = "tarsnap-keymgmt"
  
end