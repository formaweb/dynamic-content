require 'rails/generators/active_record'

module DynamicContent
  module Generators

    class InstallGenerator < ActiveRecord::Generators::Base
      desc "Installs Dynamic Content and generates the necessary migrations"

      argument :locale, type: :string, default: "en"
      argument :name, type: :string, default: "nome"

      class_option :skip_activeadmin, type: :boolean, default: false, desc: "Skip ActiveAdmin files"
      class_option :skip_initializer, type: :boolean, default: false, desc: "Skip initializer file"

      source_root File.expand_path("../templates", __FILE__)

      def copy_initializer
        return if options[:skip_initializer]

        @locale = locale =~ /-/ ? "'#{locale}'" : locale
        template 'initializer.rb.erb', 'config/initializers/dynamic_content.rb'
        template 'dragonfly_initializer.rb.erb', 'config/initializers/dragonfly.rb'
      end

      def copy_structure_file
        template 'structure.yml', 'db/seeds/dynamic_content.yml'
      end

      def setup_activeadmin
        return if options[:skip_activeadmin]

        empty_directory "app/views/admin"
        empty_directory "app/admin"
        template 'admin_pages.rb', 'app/admin/pages.rb'
        copy_file '_dynamic_inputs.html.erb', 'app/views/admin/pages/_dynamic_inputs.html.erb'
        copy_file '_forms.html.erb', 'app/views/admin/pages/_forms.html.erb'
      end

      def create_rake_task
        rakefile "dynamic_content.rake" do
          %Q{
            namespace :dynamic_content do
              desc "Update Dynamic Content structure file"
              task update: :environment do
                Rails.logger = Logger.new(STDOUT)
                DynamicContent.process
              end
            end
}
        end
      end

      def create_migrations
        migration_template 'migrations/create_dynamic_content_pages.rb.erb', 'db/migrate/create_dynamic_content_pages.rb'
        migration_template 'migrations/create_dynamic_content_sections.rb.erb', 'db/migrate/create_dynamic_content_sections.rb'
        migration_template 'migrations/create_dynamic_content_contents.rb.erb', 'db/migrate/create_dynamic_content_contents.rb'
      end
    end

  end
end
