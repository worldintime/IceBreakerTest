module CommonHelper
  def stub_mute_destroy_task
    allow(Mute).to receive(:destroy)
  end
end