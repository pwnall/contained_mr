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
  #
  # @return {Array<Docker::Container, Docker::Image>} the removed objects
  def destroy_all!
    containers = destroy_all_containers!
    images = destroy_all_images!
    containers + images
  end

  # @return {Array<Docker::Container>} the removed containers
  def destroy_all_containers!
    containers = Docker::Container.all all: true,
                                       filters: container_filters.to_json
    containers.each do |container|
      begin
        container.delete force: false, volumes: true
      rescue Docker::Error::NotFoundError
        # Workaround for https://github.com/docker/docker/issues/14474
      end
    end
  end

  # @return {Array<Docker::Image>} the removed images
  def destroy_all_images!
    tag_prefix = "#{@name_prefix}/"
    images = Docker::Image.all
    deleted_images = []
    images.each do |image|
      next unless image_tags = image.info['RepoTags']
      image_tags.each do |image_tag|
        next unless image_tag.start_with? tag_prefix
        # HACK(pwnall): Trick docker-api into issuing a DELETE request by tag.
        tag_image = Docker::Image.new Docker.connection, 'id' => image_tag
        tag_image.delete
        deleted_images << image
      end
    end
    deleted_images
  end

  # @return { Hash<Symbol, Array<String>> } filters used to identify Docker
  #   containers started by this controller
  def container_filters
    { label: [ "contained_mr.ctl=#{@label_value}" ] }
  end
end
