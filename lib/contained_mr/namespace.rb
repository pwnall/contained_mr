# Namespace and factory for templates.
module ContainedMr
  # Stubbing hook for tests.
  #
  # This method should be used instead of calling {ContainedMr::Template.new}
  # directly. This way, tests can stub this method and return
  # {ContainedMr::Mock::Template} instead of the real template.
  #
  # @return {ContainedMr::Template}
  def self.template_class
    ContainedMr::Template
  end
end
