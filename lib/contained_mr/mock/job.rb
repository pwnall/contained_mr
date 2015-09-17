# @see {ContainedMr::Job}
class ContainedMr::Mock::Job
  # @see {ContainedMr::Job}
  attr_reader :template, :id, :name_prefix, :item_count

  # @return {String} the input data provided to {#build_mapper_image}
  attr_reader :_mapper_input

  include ContainedMr::JobLogic

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

    @mappers = Array.new @item_count
    @reducer = nil
    @mapper_options = nil
    @reducer_options = nil
    @_mapper_input = nil

    @destroyed = false
    parse_options json_options

    @mock_mappers = (1..@item_count).map do |i|
      ContainedMr::Mock::Runner.new mapper_container_options(i),
        @mapper_options[:wait_time], @template.mapper_output_path
    end
    @mock_reducer = ContainedMr::Mock::Runner.new reducer_container_options,
        @reducer_options[:wait_time], @template.reducer_output_path
  end

  # @see {ContainedMr::Job#destroy}
  def destroy!
    @destroyed = true
    self
  end

  # @see {ContainedMr::Job#build_mapper_image}
  def build_mapper_image(mapper_input)
    unless @mapper_image_id.nil?
      raise RuntimeError, 'Mapper image already exists'
    end
    @_mapper_input = mapper_input
    @mapper_image_id = 'mock-job-mapper-image-id'
  end

  # @see {ContainedMr::Job#build_reducer_image}
  def build_reducer_image
    unless @reducer_image_id.nil?
      raise RuntimeError, 'Reducer image already exists'
    end
    1.upto @item_count do |i|
      raise RuntimeError, 'Not all mappers ran' if mapper_runner(i).nil?
    end
    @reducer_image_id = 'mock-job-reducer-image-id'
  end

  # @see {ContainedMr::Job#run_mapper}
  def run_mapper(i)
    if i < 1 || i > @item_count
      raise ArgumentError, "Invalid mapper number #{i}"
    end
    raise RuntimeError, 'Mapper image does not exist' if @mapper_image_id.nil?
    @mappers[i - 1] = @mock_mappers[i - 1]
  end

  # @see {ContainedMr::Job#run_reducer}
  def run_reducer
    if @reducer_image_id.nil?
      raise RuntimeError, 'Reducer image does not exist'
    end
    @reducer = @mock_reducer
  end

  # Returns the mock pretending to be the runner used for a mapper.
  #
  # @param {Number} i the mapper number
  # @return {ContainedMr::Mock::Runner} the runner that will be returned
  #   by {ContainedMr::Mock::Job#mapper_runner} after
  #   {ContainedMr::Mock::Job#run_mapper} completes.
  def _mock_mapper(i)
    if i < 1 || i > @item_count
      raise ArgumentError, "Invalid mapper number #{i}"
    end
    @mock_mapper[i - 1]
  end

  # Returns the mock pretending to be the runner used for the reducer.
  #
  # @return {ContainedMr::Mock::Runner} the mock runner that will be returned
  #   by {ContainedMr::Mock::Job#reducer_runner} after
  #   {ContainedMr::Mock::Job#run_reducer} completes.
  def _mock_reducer
    @mock_reducer
  end
end
