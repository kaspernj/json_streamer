require "spec_helper"

describe JsonStreamer::ObjectReader do
  it "works" do
    reader = JsonStreamer::ConnectedReader.new

    reader.begin_hash do
    end

    reader.begin_array do
      puts "ArrayBegin"
    end

    reader.key_dynamic_value_for_hash do |key, value_type|
      if key == "Results" && value_type == :array && reader.streamer.indent == 1
        puts "Results!"
      end
    end

    elements = 0
    reader.foreach("[Results]") do |element|
      elements += 1
    end

    File.open("#{File.dirname(__FILE__)}/test_files/small.json", "r") do |fp|
      JsonStreamer.new(reader) do |streamer|
        fp.each_char do |char|
          streamer << char
        end
      end
    end

    elements.should eq 3
  end
end
