# Natra
[![CI](https://github.com/jamesnjuguna0419/natra/actions/workflows/ci.yml/badge.svg)](https://github.com/jamesnjuguna0419/natra/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/natra.svg)](https://rubygems.org/gems/natra)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.txt)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'natra'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install natra

## Commands
```
natra -v              # Show Natra version number
natra help [COMMAND]  # Describe available commands or one specific command
natra new APP-NAME    # Creates a new Sinatra application
natra model NAME      # Generate a model
natra controller NAME # Generate a controller
natra scaffold NAME   # Generate a model with its associated views and controllers
```
The controller generator also have an optional views flag `--no-views` to create controllers without views.

## Using Natra

To generate your app:

    natra new APP-NAME

After natra is done generating your app, run `bundle install` from your app's directory:

    cd APP-NAME
    bundle install

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thirunjuguna/natra. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Natra project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/thirunjuguna/natra/blob/master/CODE_OF_CONDUCT.md).
