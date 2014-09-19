require 'rails_helper'

describe ApplicationController do
  it '#home' do
    get :home
    expect( Oj.load(response.body)['info'] ).to eq 'Wrong request'
  end
end
