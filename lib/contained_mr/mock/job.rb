# @see {ContainedMr::Job}
class ContainedMr::Mock::Job
  # @see {ContainedMr::Job}
  attr_reader :template, :id, :name_prefix, :item_count

  # @return {String} the input data provided to {#build_mapper_image}
  attr_reader :_mapper_input

  # @return {Boolean} true if {#destroy!} was called
  def destroyed?
    @destroyed
  end

  # @see {ContainedMr::Job#initialize}
  def initialize(template, id, json_options)
    @template = template
    @id = id
    @name_prefix = template.name_prefix
    @item_count = template.item_count

    @mapper_image_id = nil
    @reducer_image_id = nil
    @destroyed = false
    @mapper_runner = Array.new @item_count, :mapper
    @reducer_runner = :reducer
    @ran_mapper = Array.new @item_count, false
    @ran_reducer = false

    @_mapper_input = nil
  end

  # @see {ContainedMr::Job#destroy}
  def destroy!
    @destroyed = true
    self
  end

  # @see {ContainedMr::Job#mapper_runner}
  def mapper_runner(i)
    if i < 1 || i > @item_count
      raise ArgumentError, "Invalid mapper number #{i}"
    end
    return nil unless @ran_mapper[i - 1]
    @mapper_runner[i - 1]
  end

  # @see {ContainedMr::Job#reducer_runner}
  def reducer_runner
    return nil unless @ran_reducer
    @reducer_runner
  end

  # @see {ContainedMr::Job#build_mapper_image}
  def build_mapper_image(mapper_input)
    unless @mapper_image_id.nil?
      raise RuntimeError, 'Mapper image already exists'
    end
    @_mapper_input = mapper_input
    @mapper_image_id = ''
  end

  # @see {ContainedMr::Job#build_reducer_image}
  def build_reducer_image
    unless @reducer_image_id.nil?
      raise RuntimeError, 'Reducer image already exists'
    end
    1.upto @item_count do |i|
      raise RuntimeError, 'Not all mappers ran' if mapper_runner(i).nil?
    end
    @reducer_image_id = ''
  end

  # @see {ContainedMr::Job#run_mapper}
  def run_mapper(i)
    if i < 1 || i > @item_count
      raise ArgumentError, "Invalid mapper number #{i}"
    end
    raise RuntimeError, 'Mapper image does not exist' if @mapper_image_id.nil?
    @ran_mapper[i - 1] = true
    @mapper_runner[i - 1]
  end

  # @see {ContainedMr::Job#run_reducer}
  def run_reducer
    if @reducer_image_id.nil?
      raise RuntimeError, 'Reducer image does not exist'
    end
    @ran_reducer = true
    @reducer_runner
  end
end
