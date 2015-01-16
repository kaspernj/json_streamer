class JsonStreamer::ConnectedReader < JsonStreamer::BaseReader
  def initialize
    @connects = {}
  end

  def connect(&blk)
    connect_name = "on_#{__callee__}".to_sym

    @connects[connect_name] ||= []
    @connects[connect_name] << blk
  end

  alias begin_array connect
  alias array_value connect
  alias array_dynamic_value connect
  alias end_array connect
  alias begin_hash connect
  alias end_hash connect
  alias key_value_for_hash connect
  alias key_dynamic_value_for_hash connect

  def call(*args)
    if @connects.key?(__callee__)
      @connects[__callee__].each do |block|
        block.call(*args)
      end
    end
  end

  alias on_begin_array call
  alias on_array_value call
  alias on_array_dynamic_value call
  alias on_end_array call
  alias on_begin_hash call
  alias on_end_hash call
  alias on_key_value_for_hash call
  alias on_key_dynamic_value_for_hash call
end
