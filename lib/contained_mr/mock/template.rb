# @see {ContainedMr::Template}
class ContainedMr::Mock::Template
  # @see {ContainedMr::Template}
  attr_reader :name_prefix, :id, :item_count

  # @return {Hash<String, Object>} YAML-parsed mapreduced.yml
  attr_reader :_definition

  # @return {Hash<String, Symbol|String>} maps file names in the template .zip
  #   to their contents, and maps directory entries to the :directory symbol
  attr_reader :_zip_contents

  # @return {Boolean} true if {#destroy!} was called
  def destroyed?
    @destroyed
  end

  # @see {ContainedMr::Template#initialize}
  def initialize(name_prefix, id, zip_io)
    @name_prefix = name_prefix
    @id = id
    @destroyed = false

    @item_count = nil
    @_definition = nil
    @_zip_contents = {}

    process_zip zip_io
  end

  # @see {ContainedMr::Template#destroy!}
  def destroy!
    @destroyed = true
    self
  end

  # Reads the template .zip and parses the definition.
  def process_zip(zip_io)
    # TODO(pwnall): zip_io.read -> zip_io after rubyzip releases 1.1.8
    Zip::File.open_buffer zip_io.read do |zip|
      zip.each do |zip_entry|
        file_name = zip_entry.name
        if zip_entry.directory?
          @_zip_contents[file_name] = :directory
        elsif zip_entry.file?
          if file_name == 'mapreduced.yml'
            read_definition zip_entry.get_input_stream
            next
          end
          @_zip_contents[file_name] = zip_entry.get_input_stream.read
        end
      end
    end
    @_zip_contents.freeze
  end
  private :process_zip

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
