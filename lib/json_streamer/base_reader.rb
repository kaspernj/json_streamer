class JsonStreamer::BaseReader
  attr_accessor :streamer

  def send_event(method_name, *args, &blk)
    @current_object_reader.__send__(method_name, *args, &blk) if @current_object_reader
    __send__(method_name, *args, &blk)
  end

  def read_current_object
    @object_readers ||= []

    object_reader = JsonStreamer::ObjectReader.new(
      current_indent: streamer.indent,
      reader: self,
      streamer: streamer
    )
    @object_readers << object_reader
    @current_object_reader = object_reader

    return object_reader
  end

  def finish_object_reader(object_reader, type_finished)
    raise "Wrong object reader finished!" if @current_object_reader != object_reader
    raise "Object reader wasn't the last one!" if @object_readers.last != object_reader

    @object_readers.pop
    @current_object_reader = @object_readers.last
    @current_object_reader.__send__(:finished_sub_reader, type_finished) if @current_object_reader
  end
end
