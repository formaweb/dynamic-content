module DynamicContent
  class Section < ActiveRecord::Base
    self.table_name = 'dynamic_content_sections'

    belongs_to :page
    has_many :contents, dependent: :destroy

    accepts_nested_attributes_for :contents, allow_destroy: false
  end
end
