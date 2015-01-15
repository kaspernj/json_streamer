class JsonStreamer::ObjectReader
  attr_reader :indent, :object

  def initialize(args)
    @indent = args[:current_indent]
    @streamer = args[:streamer]
    @reader = args[:reader]
    @finished = false
    @debug = args[:debug]

    if @streamer.state == :reading_hash
      @object = {}
    elsif @streamer.state == :reading_array
      @object = []
    else
      raise "Unknown state: #{@streamer.state}"
    end
  end

  def finished?
    @finished
  end

  def result
    raise "Not finished yet" unless finished?
    return @object
  end

private

  def on_begin_array
    if @value_type == :array
      @value_reader = @reader.read_current_object
    elsif @value_type
      raise "Expected to read: #{@value_type}"
    end
  end

  def on_end_array
    if @value_type == :array
      @object[@hash_key] = @value_reader.result
      @value_type = nil
      @value_reader = nil
    elsif @value_type
      raise "Expected to finish reading: #{@value_type}"
    end

    detect_finished(:array)
  end

  def on_array_value(value)
    @object << value
  end

  def on_array_dynamic_value(value_type)
    raise "Already waiting for finished reading a dynamic value: #{@value_type}" if @value_type
    @value_type = value_type
  end

  def on_begin_hash
    if @value_type == :hash
      @value_reader = @reader.read_current_object
    elsif @value_type
      raise "Expected to read: #{@value_type}"
    end
  end

  def on_end_hash
    if @value_type == :hash
      if @object.is_a?(Hash)
        @object[@hash_key] = @value_reader.result
      elsif @object.is_a?(Array)
        @object << @value_reader.result
      end

      @hash_key = nil
      @value_type = nil
      @value_reader = nil
    elsif @value_type
      raise "Expected to finish reading: #{@value_type}"
    end

    detect_finished(:hash)
  end

  def on_key_dynamic_value_for_hash(key, value_type)
    raise "Already waiting for finishing reading a dynamic value: #{@hash_key}" if @hash_key || @value_type || @hash_value_reader
    @hash_key = key
    @value_type = value_type
  end

  def on_key_value_for_hash(key, value)
    raise "Object is not a hash: #{@object.class.name} for: #{key} => #{value}" unless @object.is_a?(Hash)
    @object[key] = value
  end

  def detect_finished(type_finished)
    if @streamer.indent == @indent
      @finished = true
      @reader.finish_object_reader(self, type_finished)
    end
  end

  def finished_sub_reader(type_finished)
    if @object.is_a?(Hash)
      raise "No hash_key was set." unless @hash_key
      @object[@hash_key] = @value_reader.result
      @hash_key, @value_reader, @value_type = nil, nil, nil
    elsif @object.is_a?(Array)
      @object << @value_reader.result
      @value_reader, @value_type = nil, nil
    end
  end
end
