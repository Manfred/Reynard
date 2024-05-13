# frozen_string_literal: true

require_relative '../../test_helper'
require 'tempfile'

class Reynard
  module Serializers
    class MultipartFormDataTest < Reynard::Test
      def boundary
        MultipartFormData::MULTIPART_BOUNDARY
      end

      test 'returns a mime-type' do
        assert_equal 'multipart/form-data', MultipartFormData.new(data: nil).mime_type
      end

      test 'returns request headers' do
        multipart_form_data = MultipartFormData.new(data: nil)
        assert_equal(
          { 'Content-Type' => %(#{multipart_form_data.mime_type}; boundary="#{boundary}") },
          multipart_form_data.headers
        )
      end

      test 'returns the multi-part boundary' do
        multipart_form_data = MultipartFormData.new(data: nil)
        assert_equal boundary, multipart_form_data.multipart_boundary
      end
    end
  end
end
