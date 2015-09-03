require 'json'

# Cleans up left over Docker images and containers.
class ContainedMr::Cleaner
  attr_reader :name_prefix

  # Sets up a cleaner.
  #
  # @param {String} name_prefix should match the value given to Template
  #   instances
  def initialize(name_prefix)
    @name_prefix = name_prefix
    @label_value = name_prefix
  end

  # Removes all images and containers matching this cleaner's name prefix.
  def destroy_all!
    destroy_all_containers!
    destroy_all_images!
  end

  def destroy_all_containers!
    containers = Docker::Container.all all: true,
                                       filters: container_filters.to_json
    containers.each do |container|
      container.delete force: false, volumes: true
    end
  end
  private :destroy_all_containers!

  def destroy_all_images!
    tag_prefix = "#{@name_prefix}/"
    images = Docker::Image.all
    images.each do |image|
      image_tags = image.info['RepoTags'] || []
      next unless image_tags.any? { |tag| tag.start_with? tag_prefix }
      image.delete
    end
  end
  private :destroy_all_images!

  # @return { Hash<Symbol, Array<String>> } filters used to identify Docker
  #   containers started by this controller
  def container_filters
    { label: [ "contained_mr.ctl=#{@label_value}" ] }
  end
end
