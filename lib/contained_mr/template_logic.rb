# Logic shared by {ContainedMr::Template} and {ContainedMr::Mock::Template}.
module ContainedMr::TemplateLogic
  # @return {String} prepended to Docker objects, for identification purposes
  attr_reader :name_prefix

  # @return {String} the template's unique identifier
  attr_reader :id

  # @return {Number} the number of mapper jobs specified by this template
  attr_reader :item_count

  # @return {String} image_id the unique ID of the Docker image used as a base
  #   for images built by jobs derived from this template
  attr_reader :image_id

  # Creates a job using this template.
  #
  # @param {String} id the job's unique ID
  # @param {Hash<String, Object>} json_options job options, extracted from JSON
  # @return {ContainedMr::Job} a newly created job that uses this template
  def new_job(id, json_options)
    job_class.new self, id, json_options
  end

  # Computes the Dockerfile used to build a job's mapper image.
  #
  # @return {String} the Dockerfile
  def mapper_dockerfile
    job_dockerfile @_definition['mapper'] || {}, 'input'
  end

  # Computes the Dockerfile used to build a job's reducer image.
  #
  # @return {String} the Dockerfile
  def reducer_dockerfile
    job_dockerfile @_definition['reducer'] || {}, '.'
  end

  # @return {String} tag applied to the template's base Docker image
  def image_tag
    "#{@name_prefix}/base.#{@id}"
  end

  # Computes the environment variables to be set in a mapper container.
  #
  # @param {Number} i the mapper number
  # @return {Array<String>} environment variables to be set in the mapper
  def mapper_env(i)
    [ "ITEM=#{i}", "ITEMS=#{@item_count.to_s}" ]
  end

  # Computes the environment variables to be set in the reducer container.
  #
  # @return {Array<String>} environment variables to be set in the mapper
  def reducer_env
    [ "ITEMS=#{@item_count.to_s}" ]
  end

  # @return {String} the map output's path in the mapper Docker container
  def mapper_output_path
    (@_definition['mapper'] || {})['output'] || '/output'
  end

  # @return {String} the reducer output's path in the reducer Docker container
  def reducer_output_path
    (@_definition['reducer'] || {})['output'] || '/output'
  end

  # @private common code from mapper_dockerfile and reducer_dockerfile
  def job_dockerfile(job_definition, input_source)
    <<DOCKER_END
FROM #{@image_id}
COPY #{input_source} #{job_definition['input'] || '/input'}
WORKDIR #{job_definition['chdir'] || '/'}
ENTRYPOINT #{JSON.dump(job_definition['cmd'] || ['/bin/sh'])}
DOCKER_END
  end
  private :job_dockerfile

  # Reads the template's definition, using data at the given path.
  #
  # @param {IO} yaml_io IO implementation that produces the .yaml file
  #   containing the definition
  def read_definition(yaml_io)
    @_definition = YAML.load yaml_io.read
    @_definition.freeze

    @item_count = @_definition['items'] || 1
  end
  private :read_definition
end
