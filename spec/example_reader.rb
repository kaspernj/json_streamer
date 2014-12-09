class ExampleReader
  def initialize(args = {})
    @results_read = false
    @reading_person = false
    @debug = args[:debug]
    @indent = 0
  end

  def on_begin_array
    debug "Begin array"
    @indent += 1
  end

  def on_end_array
    debug "End array"
    @indent -= 0
  end

  def on_begin_hash
    debug "Begin hash"
    @indent += 1
  end

  def on_end_hash
    if @reading_person && @on_person
      @on_person.call(@person)
      @person = nil
      @reading_person = false
    end

    @indent -= 0
  end

  def on_person(&blk)
    @on_person = blk
  end

  def on_key_value_for_hash(key, value)
    debug "HashKeyValue: #{key}: #{value}"

    if key == "name"
      @reading_person = true
      @person = {name: value}
    elsif @reading_person && key == "age"
      @person[:age] = value
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
    @indent.times do
      indent_str << "  "
    end

    print "#{indent_str}#{message}\n" if @debug
  end
end
