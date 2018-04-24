module DynamicContent
  class Content < ActiveRecord::Base
    self.table_name = 'dynamic_content_contents'

    belongs_to :section

    serialize :data_options, JSON

    default_scope { order('dynamic_content_contents.order ASC') }

    dragonfly_accessor :file do
      after_assign{ |a| a.thumb!('1000x1000^') if ::MIME::Types.type_for(self.file_name).first.try(:content_type).to_s.start_with? 'image' }
    end

    # hash key: dynamic content data type
    # field: where content is stored on database
    # as: formtastic input type
    # wrapper_class: css class of element wrapper, like li tag on formtastic
    # input_class: css class of input element
    INPUT_TYPES = {
      default: { field: :content, as: :string, wrapper_class: 'string', input_class: '' },
      select: { as: :select },
      boolean: { as: :boolean },
      text: { as: :text },
      markdown: { as: :text },
      editor: { as: :text, input_class: 'complete-editor' },
      embed: {},
      uploader: { field: :file, as: :file },
      image: { field: :file },
      date: { field: :date, as: :date_select },
      time: { field: :date, as: :time_select },
      datetime: { field: :date, as: :datetime_select },
      video: { as: :url },
      currency: { as: :number },
      hidden: { as: :hidden }
    }

    INPUT_MODIFIERS = {
      markdown: { string: { as: :string } },
      editor: { simple_editor: { input_class: 'simple-editor' }, 'list-editor': { input_class: 'list-editor' } }
    }

    before_validation do
      case self.data_type
      when 'editor'
        if self.type_options == 'list-editor'
          self.content = ActionController::Base.helpers.sanitize(self.content.to_s, tags: %w(ul li strong em u span), attributes: [])
          self.content = self.content[self.content.index('<ul>'), self.content.index('</ul>')] unless self.content.to_s['<ul>'].blank?
        end
      end
    end

    def get_type_options
      return @type_options unless @type_options.nil?

      @type_options = INPUT_TYPES[:default].dup
      current_type = self.data_type.to_sym

      @type_options.merge!(INPUT_TYPES[current_type]) if INPUT_TYPES.include?(current_type)

      if INPUT_MODIFIERS.include?(current_type) && INPUT_MODIFIERS[current_type].include?(self.type_options.to_sym)
        @type_options.merge!(INPUT_MODIFIERS[current_type][self.type_options.to_sym])
      end

      @type_options[:wrapper_class] += (self.has_divisor ? ' has-divisor' : '')

      return @type_options
    end

    def formtastic_compatible?
      not_compatible = %w(image uploader embed)

      return !self.has_caption && !not_compatible.include?(self.data_type.to_s)
    end

    def get_content *args
      case self.data_type
      when 'select'
        result = self.content.to_i
      when 'boolean'
        result = self.content.to_i == 1
      when 'currency'
        # result = self.content.gsub(',', '.').to_f
        result = ActionController::Base.helpers.number_to_currency(self.content.gsub(',', '.').to_f)
      when 'editor'
        result = self.content.html_safe
      when 'markdown'
        markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: false, filter_html: true, no_styles: true, no_images: true, highlight: true)
        result = markdown.render(self.content).gsub('<p>', '').gsub('</p>', '').html_safe
        self.caption = markdown.render(self.caption).gsub('<p>', '').gsub('</p>', '') if self.has_caption
      when 'embed'
        result = self.content.html_safe
      when 'uploader'
        result = self.file.url
      when 'image'
        result = {content: (self.file ? self.file.url : ''), alt: self.content, uid: self.file_uid}
      when 'date'
        result = self.date.blank? ? nil : self.date.to_date
      when 'datetime'
        result = self.date
      when 'video'
        result = {content: '', provider: :none}

        unless self.content.blank?
          parsed_url = self.content.gsub('https', 'http').match(/http:\/\/(?:www\.)?(vimeo|youtube)\.com\/(?:watch\?v=)?(.*?)(?:\z|$|&)/)

          if !parsed_url.nil? && ['youtube', 'vimeo'].include?(parsed_url[1])
            result = {
              content: parsed_url[2],
              provider: parsed_url[1].to_sym,
              link: (parsed_url[1] == 'youtube' ? "http://youtu.be/#{parsed_url[2]}" : "https://vimeo.com/#{parsed_url[2]}"),
              embed: (parsed_url[1] == 'youtube' ? "https://www.youtube.com/embed/#{parsed_url[2]}" : "https://player.vimeo.com/video/#{parsed_url[2]}?color=ffffff")
            }
          end
        end
      else
        result = self.content
      end

      result[:data_type] = self.data_type if result.kind_of?(Hash)

      if self.has_caption
        return {caption: self.caption.html_safe, content: result}
      else
        return result
      end
    end
  end
end
