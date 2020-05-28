# frozen_string_literal: true

warn [
  'Deprecation: "u-case/with_validation" will be deprecated in the next major release.',
  'Please use "u-case/with_activemodel_validation" instead of it.'
].join(' ')

require 'u-case/with_activemodel_validation'
