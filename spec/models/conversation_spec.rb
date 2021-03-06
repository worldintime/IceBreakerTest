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
      @conversation = create(:conversation, initial: 'initial', reply: 'reply', finished: 'finished')
    end

    describe 'before_update' do
      it 'should not call #mute_users' do
        expect(Mute).to_not receive(:new)
        @conversation.update(reply_viewed: false)
      end

      it 'should call #mute_users' do
        stub_mute_destroy_task
        @conversation.update(finished: false)
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
      ActionMailer::Base.deliveries.clear
      stub_mute_destroy_task
      @conversation.ignore_user(1, 2)
      expect(@conversation.mute.status).to eq 'Ignored'
    end

    describe '#existing_messages' do
      it 'without :reply, :finished' do
        @conversation.update!(reply: nil, finished: nil)
        expect(@conversation.existing_messages).to be_truthy
      end

      it 'without :finished' do
        @conversation.update!(reply: true, finished: nil)
        expect(@conversation.existing_messages).to be_truthy
      end

      it 'with :finished' do
        @conversation.update!(reply: true, finished: true)
        expect(@conversation.existing_messages).to be_truthy
      end
    end

    describe '#my_message' do
      before :each do
        @current_user = create(:user_confirmed)
        @sender = create(:user_confirmed)
      end

      it 'current_user is not sender' do
        @conversation.update(sender: @sender, receiver: @current_user)
        h = @conversation.my_message(@current_user.id)
        expect(h[:reply]).to eq @conversation.reply
        expect(h[:reply_sent_at]).to eq @conversation.reply_created_at
      end

      it 'current_user is sender' do
        @conversation.update(sender: @current_user, receiver: @sender)
        h = @conversation.my_message(@current_user.id)
        expect(h[:initial]).to eq @conversation.initial
        expect(h[:initial_sent_at]).to eq @conversation.initial_created_at
        expect(h[:finished]).to eq @conversation.finished
        expect(h[:finished_sent_at]).to eq @conversation.finished_created_at
      end
    end
  end

  describe '#unread_messages' do
    it 'should retrieve correct number' do
      user = create(:user_confirmed)
      create(:conversation)
      2.times{ create(:conversation, reply_viewed: false, sender: user) }

      current_user = create(:user_confirmed)
      2.times{ create(:conversation, sender: current_user).update(reply_viewed: false) }
      3.times{ create(:conversation, receiver: current_user).update(initial_viewed: false, finished_viewed: false) }
      # reply_viewed + initial_viewed + finished_viewed
      expect(described_class.unread_messages(current_user.id)).to eq 8
    end

    it 'should retrieve correct number after conversation was removed' do
      user = create(:user_confirmed)
      create(:conversation)
      2.times{ create(:conversation, reply_viewed: false, sender: user) }

      current_user = create(:user_confirmed)
      2.times{ create(:conversation, sender: current_user).update(reply_viewed: false, removed_by_sender: true) }
      3.times{ create(:conversation, receiver: current_user).update(initial_viewed: false, finished_viewed: false, removed_by_receiver: true) }
      # reply_viewed + initial_viewed + finished_viewed
      expect(described_class.unread_messages(current_user.id)).to eq 0
    end
  end

  describe '#remove_conversation' do

    it 'should remove conversation for sender' do
      user1 = create(:user_confirmed)
      user2 = create(:user_confirmed)

      conversation = create(:conversation, sender_id: user1.id, receiver_id: user2.id, removed_by_sender: false, removed_by_receiver: false)

      expect( conversation.remove_conversation(user1.id) ).to be_truthy
      expect( conversation.removed_by_sender ).to eq true

    end

    it 'should remove conversation for receiver' do
      user1 = create(:user_confirmed)
      user2 = create(:user_confirmed)
      conversation = create(:conversation, sender_id: user2.id, receiver_id: user1.id, removed_by_sender: false, removed_by_receiver: false)

      expect( conversation.remove_conversation(user1.id) ).to be_truthy
      expect( conversation.removed_by_receiver ).to eq true

    end

    it 'should change status removed by receiver' do
      user1 = create(:user_confirmed)
      user2 = create(:user_confirmed)
      conversation = create(:conversation, sender_id: user2.id, receiver_id: user1.id, removed_by_sender: false, removed_by_receiver: false)

      expect{ conversation.remove_conversation(user1.id) }.to change(conversation, :removed_by_receiver)

    end

    it 'should change status removed by sender' do
      user1 = create(:user_confirmed)
      user2 = create(:user_confirmed)
      conversation = create(:conversation, sender_id: user1.id, receiver_id: user2.id, removed_by_sender: false, removed_by_receiver: false)

      expect{ conversation.remove_conversation(user1.id) }.to change(conversation, :removed_by_sender)

    end

    it 'should remove conversation for both users' do
      user1 = create(:user_confirmed)
      user2 = create(:user_confirmed)
      conversation = create(:conversation, sender_id: user2.id, receiver_id: user1.id, removed_by_sender: true, removed_by_receiver: false)

      expect{conversation.remove_conversation(user1.id)}.to change(Conversation, :count).by(-1)
      expect(conversation.remove_conversation(user1.id).destroyed?).to be_truthy

    end

  end

end