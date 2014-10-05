require 'rails_helper'

describe ApplicationController do
  it '#home' do
    get :home
    expect( Oj.load(response.body)['info'] ).to eq 'Wrong request'
  end

  it 'should call #set_access_control_headers' do
    expect(subject).to receive(:set_access_control_headers)
    get :home
  end
end
