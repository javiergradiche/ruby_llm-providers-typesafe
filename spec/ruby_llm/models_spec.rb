# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Models do
  include_context 'with configured RubyLLM'

  it 'accepts versioned model ids that the listing leaves out' do
    expect(RubyLLM::Providers::Typesafe.assume_models_exist?).to be(true)
  end
end
