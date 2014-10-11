require 'rails_helper'

describe User do
  it 'should validate' do
    validate_uniqueness_of :email
    validate_uniqueness_of :user_name
    
    validate_presence_of :user_name
    validate_presence_of :email
    validate_presence_of :first_name
    validate_presence_of :last_name
    validate_presence_of :gender
    validate_presence_of :date_of_birth
  end

  it 'should create user' do
    user = build :user
    expect(user.save).to be true
  end

  it 'should add address by location data' do
    user = create(:user, latitude: 40.7127, longitude: -74.0059)
    expect( user.address ).to match /NY/
  end

  describe 'with user' do
    before :each do
      @current_user = create(:user_confirmed)
    end

    it '#create_session' do
      @current_user.create_session 'device' => 'iPad', 'device_token' => 123
      expect(@current_user.sessions.first.device_token).to eq 123.to_s
    end

    describe '#authenticate' do
      it 'via :email' do
        expect(described_class.authenticate(@current_user.email)).to eq @current_user
      end

      it 'via :user_name' do
        expect(described_class.authenticate(@current_user.user_name)).to eq @current_user
      end

      it 'via not exist email' do
        expect(described_class.authenticate('zzz@mail.com')).to eq nil
      end
    end

    describe 'email' do
      before :each do
        ActionMailer::Base.deliveries.clear
      end

      it '#send_forgot_password_email!' do
        @current_user.send_forgot_password_email!
        mail = ActionMailer::Base.deliveries.first
        expect(mail.to).to include @current_user.email
        expect(mail.subject).to match /New password for IceBr8kr account/
      end

      it '#send_facebook_password_email!' do
        @current_user.send_facebook_password_email(123)
        mail = ActionMailer::Base.deliveries.first
        expect(mail.to).to include @current_user.email
        expect(mail.subject).to match /Password and user name for IceBr8kr account/
      end
    end

    describe '#search_results' do
      before :each do
        @user = create(:user_confirmed)
      end

      describe 'Open' do
        it 'when status = `Closed` AND sender = @current_user AND receiver = @user' do
          @current_user.conversations_my << create(:conversation, status: 'Closed', receiver: @user)
          @current_user.save!
          expect(@current_user.search_results(@current_user.id)).to eq 'Open'
        end

        it 'when status = `Closed` AND sender = @user AND receiver = @current_user' do
          @user.conversations_my << create(:conversation, status: 'Closed', receiver: @current_user)
          @user.save!
          expect(@current_user.search_results(@current_user.id)).to eq 'Open'
        end
      end

      it 'Closed' do
        @current_user.conversations_my << create(:conversation, status: 'Closed', receiver: @current_user)
        @current_user.save!
        expect(@current_user.search_results(@current_user.id)).to eq 'Closed'
      end
    end

    it '#set_location' do
      @current_user.set_location('12,123', '12,34')
      expect(@current_user.latitude).to eq 12.123
      expect(@current_user.longitude).to eq 12.34
    end

    it '#reset_location!' do
      @current_user.set_location('12,123', '12,34')
      @current_user.reset_location!
      expect(@current_user.latitude).to be_nil
      expect(@current_user.longitude).to be_nil
      expect(@current_user.address).to be_nil
    end

    describe '#blocked_to' do
      before :each do
        @user = create(:user_confirmed)
      end

      describe 'muted' do
        it 'when sender = @user AND receiver = @current_user' do
          create(:mute, status: 'X', sender_id: @user.id ,receiver_id: @current_user.id)
          @user.reload
          expect(@user.blocked_to(@current_user.id)[:blocked_status]).to eq 'X'
        end

        it 'when sender = @current_user AND receiver = @user' do
          create(:mute, status: 'X', sender_id: @current_user.id ,receiver_id: @user.id)
          @current_user.reload
          expect(@user.blocked_to(@current_user.id)[:blocked_status]).to eq 'X'
        end
      end

      it 'muted is blank' do
        create(:mute, status: 'X', sender_id: @current_user.id ,receiver_id: @current_user.id)
        @current_user.reload
        expect(@current_user.blocked_to(@user.id)[:blocked_status]).to eq 'No'
      end
    end

    it '#rating_update' do
      @current_user.update(sent_rating: 1)
      user = create(:user_confirmed, received_rating: 3)
      described_class.rating_update(sender: @current_user.id, receiver: user.id)
      @current_user.reload
      user.reload

      expect(@current_user.sent_rating).to eq 2
      expect(user.received_rating).to eq 4
    end

    describe '#send_push_notification' do
      let(:notif_params){ {user_id: @current_user.id, message: 'Hi'} }

      describe 'without valid session' do
        it 'nil session' do
          expect(@current_user.sessions).to be_blank
          expect(Grocer::Notification).to_not receive(:new)
          expect(RestClient).to_not receive(:post)
          described_class.send_push_notification(notif_params)
        end

        it 'without device' do
          @current_user.sessions << create(:session, device_token: '123')
          @current_user.save!
          expect(Grocer::Notification).to_not receive(:new)
          expect(RestClient).to_not receive(:post)
          described_class.send_push_notification(notif_params)
        end

        it 'without device_token' do
          @current_user.sessions << create(:session, device: 'Android')
          @current_user.save!
          expect(Grocer::Notification).to_not receive(:new)
          expect(RestClient).to_not receive(:post)
          described_class.send_push_notification(notif_params)
        end
      end

      describe 'valid session' do
        it 'iOS' do
          @current_user.sessions << create(:session, device: 'iOS', device_token: '123')
          @current_user.save!
          expect(IceBr8kr::Application::IOS_PUSHER).to receive(:push)
          described_class.send_push_notification(notif_params)
        end

        it 'Android' do
          @current_user.sessions << [create(:session, device: 'Android', device_token: '123'),
                                     create(:session, device: 'Android', device_token: '123') ]
          @current_user.save!
          expect(RestClient).to receive(:post).twice
          described_class.send_push_notification(notif_params)
        end
      end
    end

  end


  it 'should place conversation to pending' do
    user = create(:user)
    expect{ user.place_to_pending(1, 2)
    }.to change(PendingConversation, :count).by(1)
  end

  it 'should remove conversation from pending' do
    user = create(:user, latitude: 40.7127, longitude: -74.0059)
    user2 = create(:user, latitude: 40.7127, longitude: -74.0059)
    user3 = create(:user, latitude: 40.0027, longitude: -74.6669)
    conversation = create(:conversation, sender_id: user.id, receiver_id: user2.id)
    pending1 = create( :pending_conversation, sender_id: user.id, receiver_id: user2.id, conversation_id: conversation.id)
    expect{ user.back_in_radius
    }.to change(PendingConversation, :count).by(-1)
    pending2 = create( :pending_conversation, sender_id: user.id, receiver_id: user3.id, conversation_id: conversation.id)
    expect{ user.back_in_radius
    }.to change(PendingConversation, :count).by(0)
  end

  it 'should return true or false if user in radius or out' do
    user = create(:user, latitude: 40.7127, longitude: -74.0059)
    user2 = create(:user, latitude: 40.7127, longitude: -74.0059)
    user3 = create(:user, latitude: 40.0027, longitude: -74.6669)

    expect( user.in_radius?(user2.id) ).to eq true
    expect( user.in_radius?(user3.id) ).to eq false
  end

end
