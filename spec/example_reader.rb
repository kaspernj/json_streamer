class ExampleReader < JsonStreamer::BaseReader
  attr_reader :persons

  def initialize(args = {})
    @results_read = false
    @reading_person = false
    @persons = []
    @debug = args[:debug]
  end

  def on_begin_array
    debug "Begin array"
  end

  def on_array_value(value)
    debug "ArrayValue: #{value}"
  end

  def on_array_dynamic_value(value_type)
    debug "ArrayDynamicValue: #{value_type}"
  end

  def on_end_array
    debug "End array"
  end

  def on_begin_hash
    debug "Begin hash"

    if streamer.indent == 2
      @person_reader = read_current_object
    end
  end

  def on_end_hash
    if streamer.indent == 2
      @persons << @person_reader.result
      @person_reader = nil
    end

    if @reading_person && @on_person
      @on_person.call(@person)
      @person = nil
      @reading_person = false
    end

    debug "End hash"
  end

  def on_person(&blk)
    @on_person = blk
  end

  def on_key_value_for_hash(key, value)
    debug "HashKeyValue(#{streamer.indent}): #{key}: #{value}"

    if key == "name"
      @reading_person = true
      @person = {"name" => value}
    elsif @reading_person && key == "age"
      @person["age"] = value
    end
  end

  def on_key_dynamic_value_for_hash(key, value_type)
    debug "HashKeyWithType: #{key}: (#{value_type})"

    if key == "Results" && !@results_read
      @results_read = true
    end
  end

private

  def debug(message)
    indent_str = ""
    streamer.indent.times do
      indent_str << "  "
    end

    print "(#{streamer.indent}) #{indent_str}#{message}\n" if @debug
  end
end
