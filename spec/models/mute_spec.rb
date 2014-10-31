require 'rails_helper'

describe Mute do
  it 'should create mute' do
    mute = build :mute
    expect(mute.save).to be true
  end

  it 'should show how many minutes are left until the end of mute' do
    mute = Mute.create
    expect(mute.blocked_timer).to eq 60
  end
end

