# Dynamic Content

Welcome to Dynamic Content Ruby Gem!

Simple way to manage dynamic fields with editable content on database for Rails and ActiveAdmin.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dynamic_content'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dynamic_content

And then execute:

    $ rails g dynamic_content:install

Or you can customize the installation:

    $ rails g dynamic_content:install --skip-activeadmin # Skip generate ActiveAdmin files
    $ rails g dynamic_content:install --skip-initializer # Skip generate initializer file
    $ rails g dynamic_content:install pt-BR # Setting locale on initializer

Migrate database:

    $ rake db:migrate

And then execute rake task to update your structure:

    $ rake dynamic_content:update


## Usage

### Configuring

You can configure all of Dynamic Content on initializer file.

```ruby
# initializers/dynamic_content.rb

DynamicContent.setup do |config|
  # Set locale, default is english
  config.locale = :en

  # Set structure file, with contains all of your fields structure
  config.structure_path = 'db/seeds/dynamic_content.yml'
end

# You also can change setup parameters directly
DynamicContent.structure_path = 'lib/my-fields.yml'
DynamicContent.locale = 'pt-BR'
```

Setting up Dynamic Content into your Application Controller

```ruby
# app/controllers/application_controller.rb

# add dynamic content callback
before_action :load_dynamic_content

# if you want, you can change the key for find your content
before_action -> { load_dynamic_content("#{action_name}_#{controller_name}") }
```

On your view, call to wanted content like:

```erb
# to load some content
<%= c :sample, :sample_field %>

# to load image from content
<%= c_image_tag :sample, :image_field, size: '300x300#' %>
```

## Upcoming features

### Gem level

- Use I18n on views and admin files
- All data types examples of structure file and how to get it
- Multi-locale support
- View analyzer to auto-generate structure file
- Nested fields data type setting on sections

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Testing on Rails

    gem 'dynamic_content', path: '/path/to/your/gem'

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/dynamic_content.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
