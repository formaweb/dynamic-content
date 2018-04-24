# encoding: UTF-8

ActiveAdmin.register Page do
  menu label: 'Páginas', priority: 2, parent: 'Conteúdo'
  config.sort_order = 'id_asc'
  config.per_page = 20

  actions :all, :except => [:destroy, :new, :create]

  permit_params :title, :description, keywords: [], sections_attributes: [:id, contents_attributes: [:id, :content, :caption, :file, :date]]

  filter :title
  filter :description
  filter :keywords

  index do
    column :name
    column :title
    column(:updated_at) { |page| l(page.updated_at, format: :short) }
    actions
  end

  collection_action :search_address, :method => :get do
    return render text: 'Not Found', status: 404 if params[:address].blank?

    address = URI.encode(params[:address])
    begin
      json = JSON.parse(open("https://maps.googleapis.com/maps/api/geocode/json?address=#{address}").read)

      latitude = json['results'][0]['geometry']['location']['lat']
      longitude = json['results'][0]['geometry']['location']['lng']

      return render json: { latitude: latitude, longitude: longitude }
    rescue
      return render text: 'Não encontrado latitude e longitude pelo GoogleMaps', status: 400
    end

    return render text: 'Not Found', status: 404
  end

  show do |page|
    panel "Detalhes", :class => 'details' do
      attributes_table_for page do
        row :name
        row :title
        row :description
        row(:keywords) { |page| page.keywords.blank? ? nil : page.keywords.to_sentence }
        row :updated_at
      end
    end

    page.sections.each do |section|
      panel section.name, :class => section.slug do
        attributes_table_for section do
          section.contents.each do |content|
            row_class = content.has_divisor ? 'with-divisor' : ''

            case content.data_type
            when 'select'
              row(content.name, class: row_class) { !content.data_options.include?((content.content.to_i - 1)) ? content.data_options[(content.content.to_i-1)][0] : 'Não informado' }
            when 'image'
              row(content.name, class: row_class) { image_tag(content.file.thumb('150x').url, alt: content.content, title: content.content) }
            when 'uploader'
              row(content.name, class: row_class) { content.file ? link_to('baixar arquivo atual', content.file.url, target: '_blank') : nil }
            when 'boolean'
              row(content.name, class: row_class) { content.content.to_i == 1 ? status_tag('Sim', :ok) : status_tag('Não', :error) }
            when 'currency'
              row(content.name, class: row_class) { number_to_currency(content.content.gsub(',', '.').to_f) }
            when 'date'
              row(content.name, class: row_class) { content.date.blank? ? 'Não informado' : l(content.date.to_date) }
            when 'datetime'
              row(content.name, class: row_class) { content.date.blank? ? 'Não informado' : l(content.date) }
            when 'text'
              row(content.name, class: row_class) { simple_format(content.content.to_s) }
            when 'markdown'
              row(content.name, class: row_class) { (content.has_caption ? content.get_content.values.join('<br><hr>') : content.get_content.to_s).html_safe }
            when 'hidden'
              next
            else
              row(content.name, class: row_class) { (content.content.to_s + (content.has_caption ? '<br>' + content.caption : '')).html_safe }
            end
          end
        end
      end
    end
  end

  form :partial => 'form'

  controller do
    private
    before_action :only => [:show] do
      response.headers['X-XSS-Protection'] = "0"
    end

    def scoped_collection
      return end_of_association_chain.where('id != 1')
    end
  end

end
