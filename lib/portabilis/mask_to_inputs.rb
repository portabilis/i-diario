module Portabilis
  module MaskToInputs
    def input_html_options
      options = super

      if has_mask?
        options['size'] ||= mask.length
        options['data-mask'] ||= mask
      end

      options
    end

    def has_mask?
      !!mask
    end

    def mask
      return unless has_validators?

      mask_validator = find_mask_validator || return
      mask_validator.options[:with]
    end

    def find_mask_validator
      find_validator(MaskValidator.kind)
    end
  end
end
