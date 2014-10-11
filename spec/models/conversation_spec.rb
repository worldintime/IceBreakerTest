require 'rails_helper'

describe Conversation do

  it 'should validate' do
    validate_presence_of :sender_id
    validate_presence_of :receiver_id
  end

  describe 'before_create' do
    it 'should create conversation with default view statuses' do
      conversation = Conversation.create!(sender_id: 1, receiver_id: 2)
      expect(conversation.initial_viewed).to be_falsey
      expect(conversation.reply_viewed).to be_truthy
      expect(conversation.finished_viewed).to be_truthy
    end
  end

  describe 'with conversation' do
    before :each do
      @conversation = create(:conversation)
    end

    describe 'before_update' do
      it 'should not call #mute_users' do
        expect(Mute).to_not receive(:new)
        @conversation.update(reply_viewed: false)
      end

      it 'should call #mute_users' do
        @conversation.update(finished: true)
        expect(@conversation.mute.status).to eq 'Muted'
      end
    end

    it '#check_if_already_received?'  do
      expect(@conversation.check_if_already_received?(2, 1)).to be_falsey

      Timecop.freeze(25.minutes.from_now) do
        expect(@conversation.check_if_already_received?(2, 1)).to be_falsey
      end

      Timecop.freeze(30.minutes.from_now) do
        expect(@conversation.check_if_already_received?(2, 1)).to be_truthy
      end
    end

    it '#ignore_user' do
      expect_any_instance_of(Rufus::Scheduler).to receive(:at)
      @conversation.ignore_user(1, 2)
      expect(@conversation.mute.status).to eq 'Ignored'
    end

    describe '#existing_messages' do
      it 'without :reply, :finished' do
        @conversation.update!(reply: nil, finished: nil)
        expect(@conversation.existing_messages).to eq({initial_viewed: true})
      end

      it 'without :finished' do
        @conversation.update!(reply: true, finished: nil)
        expect(@conversation.existing_messages).to eq({reply_viewed: true})
      end

      it 'with :finished' do
        @conversation.update!(reply: true, finished: true)
        expect(@conversation.existing_messages).to eq({finished_viewed: true})
      end
    end

    describe '#ignored' do
      it 'without Mute' do
        expect(@conversation.ignored).to be_falsey
      end

      it 'with Mute' do
        @conversation.mute = build(:mute)
        @conversation.save!
        expect(@conversation.ignored).to be_truthy
      end
    end

    describe '#check_if_sender' do
      before :each do
        @current_user = create(:user_confirmed)
        @sender = create(:user_confirmed)
      end

      it 'current_user is not sender' do
        @conversation.update(sender: @sender, receiver: @current_user)
        h = @conversation.check_if_sender(@current_user.id)
        expect(h[:opponent][:id]).to eq @conversation.sender_id
      end

      it 'current_user is sender' do
        @conversation.update(sender: @current_user, receiver: @sender)
        h = @conversation.check_if_sender(@current_user.id)
        expect(h[:opponent][:id]).to eq @conversation.receiver_id
      end
    end
  end

  it '#unread_messages' do
    user = create(:user_confirmed)
    create(:conversation)
    2.times{ create(:conversation, reply_viewed: false, sender: user) }

    current_user = create(:user_confirmed)
    2.times{ create(:conversation, sender: current_user).update(reply_viewed: false) }
    3.times{ create(:conversation, receiver: current_user).update(initial_viewed: false, finished_viewed: false) }
    # reply_viewed + initial_viewed + finished_viewed
    expect(described_class.unread_messages(current_user.id)).to eq 8
  end

end