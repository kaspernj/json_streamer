[![Build Status](https://api.shippable.com/projects/54874decd46935d5fbbfc24f/badge?branchName=master)](https://app.shippable.com/projects/54874decd46935d5fbbfc24f/builds/latest)
[![Code Climate](https://codeclimate.com/github/kaspernj/json_streamer/badges/gpa.svg)](https://codeclimate.com/github/kaspernj/json_streamer)
[![Test Coverage](https://codeclimate.com/github/kaspernj/json_streamer/badges/coverage.svg)](https://codeclimate.com/github/kaspernj/json_streamer)

# JsonStreamer

Stream huge JSON files in Ruby for JSON based frameworks.

## Installation

Add it to your Gemfile and bundle:
```ruby
gem "json_streamer"
```

## Usage

Make your own ExampleReader class that receives events, as JSON streamer is reading through the JSON file.

```ruby
example_reader = ExampleReader.new

File.open("file.json", "r") do |fp|
JsonStreamer.new(example_reader) do |streamer|
  fp.each_line do |line|
    streamer << line
  end
end
```

## Contributing to json_streamer

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2014 kaspernj. See LICENSE.txt for
further details.

