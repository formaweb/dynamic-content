require 'active_support/core_ext'
require 'set'

require 'dragonfly'
require 'mime-types'

module DynamicContent
  autoload :VERSION, 'dynamic_content/version'
  autoload :TagSerializer, 'dynamic_content/tag_serializer'
  autoload :Processor, 'dynamic_content/processor'

  class << self
    # Structure file path
    attr_accessor :structure_path

    # Locale
    attr_accessor :locale
  end

  def self.locale
    @locale || :en
  end

  def self.structure_path
    @structure_path || 'db/seeds/dynamic_content.yml'
  end

  def self.structure_file
    if File.exists? Rails.root.join(self.structure_path)
      return YAML.load(File.read(Rails.root.join(self.structure_path)))
    else
      raise NoStructureFileError, "File #{self.structure_path} is not found."
    end
  end

  def self.setup(&block)
    yield self
  end

  def self.process
    Processor.new
  end

  def self.settings
    {
      locale: self.locale,
      structure_path: self.structure_path
    }
  end

end

ActionController::Base.class_eval do
  private
  def load_dynamic_content finder_key = nil
    unless dc_is_admin?
      finder_key ||= controller_name

      @application = DynamicContent::Page.cached_for('application')
      @page = DynamicContent::Page.cached_for(finder_key)
      @dynamic_content = @application.merge(@page)
    end
  end

  def dc_is_admin?
    params[:controller] =~ /admin/ || params[:controller] =~ /redactor/
  end
end

# Require things that don't support autoload
require 'dynamic_content/engine'
require 'dynamic_content/error'
