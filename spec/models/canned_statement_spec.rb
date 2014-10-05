require 'rails_helper'

describe CannedStatement do
  it 'should validate' do
    validate_presence_of :body
  end
end