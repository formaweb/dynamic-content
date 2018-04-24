# frozen_string_literal: true

module DynamicContentHelper

  def c_image_tag section, content, *args
    image, data, options = '', @dynamic_content, { alt: nil, size: '' }
    options = options.merge(args.first) if args.count > 0

    if data.has_key?(section.to_sym) && data[section.to_sym].has_key?(content.to_sym)
      data = data[section.to_sym][content.to_sym]

      begin
        options[:alt] = data[:alt] if options[:alt].blank?
        image = data[:content]

        if data[:data_type] == 'image' && !options[:size].blank? && data[:uid].split('.').last != 'svg'
          image = Dragonfly.app.fetch(data[:uid]).thumb(options[:size]).url
        end
      rescue
        Rails.logger.warn('WARNING: Error to load dynamic image '+section.to_s+':'+content.to_s+'.')
      end
    else
      Rails.logger.warn('WARNING: Dynamic image data for '+section.to_s+':'+content.to_s+' was not found on database.')
    end

    options.delete(:size)
    return options[:only_path] ? image : image_tag(image, options)
  end

  def c_image_path section, content, *args
    options = { only_path: true }
    options = options.merge(args.first) if args.count > 0

    return c_image_tag(section, content, options)
  end

  def c section, content, *args
    options = {default: '', preend: '', append: '', size: '', show: :content, only_numbers: false}
    options = options.merge(args.first) if args.count > 0
    data = @dynamic_content

    # options[:append] += link_to_edit(section, content) if current_admin_user && !options[:only_numbers]

    if data.has_key?(section.to_sym) && data[section.to_sym].has_key?(content.to_sym)
      result = data[section.to_sym][content.to_sym]
      result = Dragonfly.app.fetch(result[:uid]).thumb(options[:size]).url if result.kind_of?(Hash) && result.has_key?(:uid) && !options[:size].blank?
      result = result[options[:show].to_sym] if result.kind_of?(Hash)
      result = options[:default] if result.blank?
      result = result.scan(/\d/).join if options[:only_numbers]
    else
      Rails.logger.warn('WARNING: Dynamic content data for '+section.to_s+':'+content.to_s+' was not found on database.')
      result = options[:default]
    end

    return result.kind_of?(String) ? (result.blank? ? '' : (options[:preend].html_safe + result + options[:append].html_safe)) : result
  end

  def link_to_edit section, content
    if @page.has_key?(section.to_sym) && @page[section.to_sym].has_key?(content.to_sym)
      id = @page[:id]
    elsif @application.has_key?(section.to_sym) && @application[section.to_sym].has_key?(content.to_sym)
      id = @application[:id]
    else
      return ''
    end

    return (' ' + link_to('', edit_admin_page_path(id)+'#'+section.to_s+'-'+content.to_s, class: 'admin-edit', data: {section: section, content: content, page: id}, title: 'Editar', target: '_blank'))
  end

end
