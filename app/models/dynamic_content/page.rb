module DynamicContent
  class Page < ActiveRecord::Base
    self.table_name = 'dynamic_content_pages'

    has_many :sections, dependent: :destroy
    accepts_nested_attributes_for :sections, allow_destroy: false

    scope :get_page, -> (page){ includes(:sections).find_by_slug(page) }

    after_commit :flush_cache

    serialize :keywords, TagSerializer.new

    def self.load page
      current = self.includes(:sections).find_by_slug(page)
      return {} if current.nil?

      results = {
        id: current.id,
        title: current.title,
        keywords: current.keywords.try(:join, ', '),
        description: current.description
      }

      sections_content = current.sections#.where(on_application: false)
      sections_content = sections_content + Section.where(on_application: true) if page == 'application'

      sections_content.each do |section|
        results[section.slug.to_sym] = {
          name: section.name
        }
        section.contents.each do |content|
          results[section.slug.to_sym][content.slug.to_sym] = content.get_content
        end
      end

      return results
    end

    def self.cached_for page
      Rails.cache.fetch([name, ("cached_page_#{page}".downcase)]) { Page.load(page) }
    end

    def flush_cache
      Rails.cache.delete([self.class.name, ("cached_page_#{self.slug}".downcase)])
      Rails.cache.delete([self.class.name, ("cached_page_application".downcase)])
    end
  end

end
