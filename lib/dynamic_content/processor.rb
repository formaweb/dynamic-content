module DynamicContent
  class Processor

    def initialize
      initial_ar_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      puts_logger("\nFormaweb Dynamic Content #{VERSION}\n\nVerifing changes on Dynamic Contents...\n")
      data = DynamicContent.structure_file

      @messages = []

      current_pages = Page.all.map{ |a| [a.slug.to_sym, a] }.to_h
      page_order = 1

      data.each do |page_slug, page|
        current_page = current_pages[page_slug.to_sym]

        if current_page
          puts_logger("\n#{page['name']} (#{page_slug})")
        else
          puts_logger("\n#{page['name']} (#{page_slug}) [ NEW ]")
          current_page = Page.new(
            title: page['title'], slug: page_slug,
            description: page['description'], keywords: page['keywords']
          )
        end

        current_page.name = page['name']
        current_page.order = page_order
        current_page.save

        ## Sections
        current_sections = current_page.sections.map{ |a| [a.slug.to_sym, a] }.to_h
        section_order = 1

        page['sections'] = [] unless page['sections']

        page['sections'].each do |section_slug, section|
          current_section = current_sections[section_slug.to_sym]

          if current_section
            puts_logger("  #{section['name']} (#{section_slug})")
          else
            puts_logger("  #{section['name']} (#{section_slug}) [ NEW ]")
            current_section = current_page.sections.new(slug: section_slug)
          end

          current_section.assign_attributes(
            name: section['name'], order: section_order,
            on_application: (section['on_application'].to_s == 'true')
          )
          current_section.save

          ## Contents
          current_contents = current_section.contents.map{ |a| [a.slug.to_sym, a] }.to_h
          content_order = 1

          raise InvalidStructureError, "Error: #{page_slug}/#{section_slug} has no contents! Unable to continue." unless section['contents']

          section['contents'].each do |content_slug, content|
            current_content = current_contents[content_slug.to_sym]

            if current_content
              puts_logger("    #{content['name']} (#{content_slug})")
            else
              puts_logger("    #{content['name']} (#{content_slug}) [ NEW ]")
              current_content = current_section.contents.new({
                slug: content_slug,
                content: content['content'],
                caption: content['caption'],
                locale: DynamicContent.locale,
                file: (content['file'] && !content['file'].blank? ? File.open(Rails.root.join(content['file'])) : nil),
                date: content['date'],
              }.delete_if { |k, v| v.nil? })
            end

            current_content.assign_attributes({
              order: content_order,
              name: content['name'],
              has_caption: (content['has_caption'].to_s == 'true' || !content['caption'].to_s.blank?),
              caption: (current_content.caption.blank? && !content['caption'].blank? ? content['caption'] : nil),
              data_options: content['data_options'],
              locale: content['locale'],
              data_type: content['data_type'],
              type_options: content['type_options'],
              handler_class: content['handler_class'],
              has_divisor: content['has_divisor'].to_s == 'true',
              hint: content['hint'],
            }.delete_if { |k, v| v.nil? })

            current_content.save

            current_contents.delete(content_slug.to_sym)
            content_order += 1
          end

          puts_logger("    Contents to destroy:") if current_contents.count > 0
          current_contents.each do |content_slug, content|
            puts_warning "    #{content.name} (#{content_slug}) [ DELETED ]"
            content.destroy # TODO: may be a way to identify slug renames
          end

          current_sections.delete(section_slug.to_sym)
          section_order += 1
        end

        puts_logger("  Sections to destroy:") if current_sections.count > 0
        current_sections.each do |section_slug, section|
          puts_warning "    #{section.name} (#{section_slug}) [ DELETED ]"
          section.destroy # TODO: may be a way to identify slug renames
        end

        current_pages.delete(page_slug.to_sym)
        page_order += 1
      end

      puts_logger("\nPages to destroy:") if current_pages.count > 0
      current_pages.each do |page_slug, page|
        puts_warning "Page #{page.name} (#{page_slug}) [ DELETED ]"
        page.destroy
      end

      if @messages.count > 0
        puts_logger("\n\n\e[31mWarning messages:\e[0m")
        @messages.map{ |m| puts_logger("  #{m}") }
      end

      puts_logger("\n\nProcess completed successfully.\n\n")

      ActiveRecord::Base.logger = initial_ar_logger
      return nil
    end

    def puts_warning message
      @messages << message.strip
      puts_logger("\e[31m#{message}\e[0m")
    end

    def puts_logger message
      # TODO: option for puts or Rails.logger.info
      puts message
    end

    def inspect; "Formaweb DynamicContent #{VERSION}" end

  end
end
