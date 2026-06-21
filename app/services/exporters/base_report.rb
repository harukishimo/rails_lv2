module Exporters
  class BaseReport
    BATCH_SIZE = 500

    def initialize(generated_at: Time.zone.now)
      @generated_at = generated_at
    end

    def key
      self.class::KEY
    end

    def title
      self.class::TITLE
    end

    def filename(extension)
      "#{key}-#{generated_at.strftime('%Y%m%d%H%M%S')}.#{extension}"
    end

    def headers
      self.class::HEADERS
    end

    def each_row
      raise NotImplementedError, "#{self.class.name} must implement #each_row"
    end

    private

    attr_reader :generated_at

    def batch_each(relation, &block)
      relation.reorder(id: :asc).find_each(batch_size: BATCH_SIZE, &block)
    end

    def text(value)
      value.to_s
    end
  end
end
