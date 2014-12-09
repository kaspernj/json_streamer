require "spec_helper"

describe "JsonStreamer" do
  it "works" do
    persons = [
      {name: "Kasper", age: 29},
      {name: "Christina", age: 27},
      {name: "Name With Space", age: 5},
      {name: "Escaped \" \t \r \n Values", age: 35.0}
    ]

    example_reader = ExampleReader.new

    person_count = 0
    example_reader.on_person do |person|
      person_saved = persons[person_count]
      person_saved.each do |key, value|
        person[key].should eq value
      end

      person_count += 1
    end

    File.open("#{File.dirname(__FILE__)}/test_files/small.json", "r") do |fp|
      JsonStreamer.new(example_reader) do |streamer|
        fp.each_char do |char|
          streamer << char
        end
      end
    end

    person_count.should eq 4
  end
end
