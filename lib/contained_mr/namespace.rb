# Namespace and factory for templates.
module ContainedMr
  # Sets up the template and builds its Docker base image.
  #
  # This method should be used instead of calling {ContainedMr::Template.new}
  # directly. This way, tests can stub {ContainedMr.template_class} to have it
  # return {ContainedMr::Mock::Template}.
  #
  # @param {String} name_prefix prepended to Docker objects, for identification
  #   purposes
  # @param {String} id the template's unique identifier
  # @param {String} zip_io IO implementation that produces the template .zip
  def self.new_template(name_prefix, id, zip_io)
    template_class.new name_prefix, id, zip_io
  end

  # The class instantiated by {ContainedMr.new_template}.
  #
  # @return {Class} by default {ContainedMr::Template}; tests should stub this
  #   method and have it return {ContainedMr::Mock::Template}
  def self.template_class
    ContainedMr::Template
  end
end
