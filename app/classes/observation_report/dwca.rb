# frozen_string_literal: true

module ObservationReport
  # Darwin Core Archive format.
  class Dwca < ObservationReport::ZipReport
    attr_accessor :observations
    attr_accessor :images

    def initialize(args)
      super(args)
      self.observations = Darwin::Observations.new(args)
      args[:observations] = self.observations
      self.images = Darwin::Images.new(args)
    end

    def filename
      "dwca.#{extension}"
    end

    # generate CSV & meta.xml and bundle into a Zip
    def render
      filename = "#{::Rails.root}/public/dwca/meta.xml"
      content << ["meta.xml", File.open(filename).read]
      content << ["observations.csv", observations.render]
      content << ["multimedia.csv", images.render]
      super
    end
  end
end
