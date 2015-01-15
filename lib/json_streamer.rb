require "thread_queues"

class JsonStreamer
  # Autoload found sub-constants
  def self.const_missing(name)
    path = "#{File.dirname(__FILE__)}/json_streamer/#{StringCases.camel_to_snake(name)}.rb"

    if File.exists?(path)
      require path
      return JsonStreamer.const_get(name)
    end

    super
  end

  attr_reader :indent, :state

  ESCAPED_VALUES = ["t", "n", "\"", "r"]

  def initialize(reader)
    @reader = reader
    @reader.streamer = self
    @queue = ThreadQueues::BufferedQueue.new(25)
    @string_buffer = ThreadQueues::StringBuffer.new(@queue)
    @buffer = ""
    @objects = []
    @closed = false
    @indent = 0

    @parse_thread = Thread.new do
      Thread.current.abort_on_exception = true
      start_parse
    end

    begin
      yield self
    ensure
      @closed = true
      @queue.close
      sleep 0.1
      @parse_thread.join
    end
  end

  def <<(content)
    @queue.push(content)
  end

private

  def start_parse
    parse_new_object
  end

  def detect_result(args)
    if args[:value_type]
      if @detect_hash_result
        @reader.send_event(:on_key_dynamic_value_for_hash, @detect_hash_result[:key_result][:value], args[:value_type])
        @detect_hash_result = nil
      elsif @detect_type_array && args[:value_type]
        @reader.send_event(:on_array_dynamic_value, args[:value_type])
        @detect_type_array = nil
      end
    elsif args[:value] && @detect_hash_result
      @reader.send_event(:on_key_value_for_hash, @detect_hash_result[:key_result][:value], args[:value])
      @detect_hash_result = nil
    end
  end

  def parse_new_object
    if regex(/\A\s*{/)
      @state = :reading_hash
      detect_result(value_type: :hash)
      on_hash
      result = {type: :hash}
    elsif regex(/\A\s*\[/)
      @state = :reading_array
      detect_result(value_type: :array)
      on_array
      result = {type: :array}
    elsif regex(/\A\s*"/)
      string_value = on_string
      detect_result(value: string_value)
      result = {type: :string, value: string_value}
    elsif match = regex(/\A\s*(\d+([\.\d]*|))\s*/)
      if match[2].empty?
        result = {type: :integer, value: match[0].to_i}
      else
        result = {type: :float, value: match[0].to_f}
      end

      detect_result(value: result[:value])
    else
      raise "Didnt know how to parse: #{@buffer}"
    end

    return result
  end

  def on_array
    @reader.send_event(:on_begin_array)
    @indent += 1
    on_array_values
  end

  def on_array_values
    loop do
      @detect_type_array = true
      result = parse_new_object
      @detect_type_array = nil

      if result[:value]
        @reader.send_event(:on_array_value, result[:value])
      end

      if regex(/\A\s*,/)
        # Continue reading array values.
      elsif regex(/\A\s*\]/)
        @indent -= 1
        @reader.send_event(:on_end_array)
        break
      end
    end
  end

  def on_hash
    @reader.send_event(:on_begin_hash)
    @indent += 1
    on_hash_pairs
  end

  def on_string
    str = ""

    loop do
      if match = regex(/\A([\s\S]+?)(\\(.)|")/)
        str << match[1]

        if match[2] == '"'
          return str
        elsif match[2].slice(0, 1) == "\\"
          if ESCAPED_VALUES.include?(match[3])
            str << eval("\"\\#{match[3]}\"")
          else
            raise "Don't know how to parse special character: \\#{match[3]}"
          end
        else
          raise "Don't know what to do parsing the string: #{@buffer}"
        end
      else
        raise "Don't know what to do: #{@buffer}"
      end
    end
  end

  def on_hash_pairs
    loop do
      if match = regex(/\A\s*([A-z_]+?)\s*:/)
        key_result = {type: :string, value: match[1]}
      else
        key_result = parse_new_object

        unless regex(/\A\s*:/)
          raise "Expected hash key-value separator: #{@buffer}"
        end
      end

      @detect_hash_result = {
        key_result: key_result
      }

      value_result = parse_new_object

      if regex(/\A\s*,/)
        # Continue loop.
      elsif regex(/\A\s*}/)
        @indent -= 1
        @reader.send_event(:on_end_hash)
        break
      else
        raise "Dunno how to continue with hash from buffer: #{@buffer}"
      end
    end
  end

  def regex(regex)
    store_more_in_buffer if @buffer.length < 512

    if match = @buffer.match(regex)
      @buffer.gsub!(regex, "")
      return match
    end

    return false
  end

  def store_more_in_buffer
    return false if @closed
    content = @string_buffer.read(512)
    return false unless content
    @buffer << content
  end
end
