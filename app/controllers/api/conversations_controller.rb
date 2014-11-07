class Api::ConversationsController < ApplicationController
  before_action :api_authenticate_user
  
  swagger_controller :conversations, "Conversation Management"

  # :nocov:
  swagger_api :messaging do
    summary "Messaging between users"
    param :query, :authentication_token, :string, :required, "Authentication token"
    param :query, :sender_id, :integer, :required, "Sender id"
    param :query, :receiver_id, :integer, :required, "Receiver id"
    param :query, :type, :string, :required, "Message type: initial/reply/finished/ignore"
    param :query, :msg, :string, :required, "Message"
    param :query, :conversation_id, :integer, :required, "Conversation id. Receives after type:initial, and required for other types"
  end
  # :nocov:

  def messaging
    muted = Mute.where(sender_id: [params[:sender_id],params[:receiver_id]],
                       receiver_id: [params[:receiver_id],params[:sender_id]])
    if muted.any?
      render json: { success: false,
                     info: "You have #{muted.first.blocked_timer} minutes before another conversation can be started!" }
    else
      message = "#{@current_user.user_name} : #{params[:msg]}"
      case params[:type]
        when 'initial'
          conversation = Conversation.new(sender_id: params[:sender_id], receiver_id: params[:receiver_id],
                                          initial: params[:msg], status: 'Closed', initial_created_at: Time.now)
          if @current_user.in_radius?(params[:receiver_id])
            if conversation.check_if_already_received?(params[:sender_id], params[:receiver_id])
              if conversation.save
                User.rating_update({sender: params[:sender_id], receiver: params[:receiver_id], fb_rating: 1})
                User.send_push_notification({user_id: params[:receiver_id], message: message})
                render json: { success: true,
                               info: 'Message sent',
                               data: { conversation_id: conversation.id },
                               status: 200 }
              else
                render json: { errors: conversation.errors.full_messages, success: false }, status: 200
              end
            else
              render json: { success: false, info: 'This user already sent a digital hello to you few minutes ago'}
            end
          else
            render json: { errors: 'You are out of radius'}
          end
        when 'reply'
          if @current_user.in_radius?(params[:receiver_id])
            conversation = Conversation.find(params[:conversation_id])
            if conversation.update_attributes!(reply: params[:msg], reply_viewed: 0, reply_created_at: Time.now)
              User.rating_update({sender: params[:sender_id], receiver: params[:receiver_id], fb_rating: 0})
              User.send_push_notification({user_id: params[:receiver_id], message: message})
              render json: { success: true,
                             info: 'Message sent',
                             data: { conversation_id: conversation.id },
                             status: 200 }
            else
              render json: { errors: conversation.errors.full_messages, success: false }, status: 200
            end
          else
            @current_user.place_to_pending(params[:conversation_id], params[:receiver_id])
            render json: { errors: 'You are out of radius'}
          end
        when 'finished'
          if @current_user.in_radius?(params[:receiver_id])
            conversation = Conversation.find(params[:conversation_id])
            if conversation.update_attributes!(finished: params[:msg], finished_viewed: false, status: 'Open', finished_created_at: Time.now)
              User.rating_update({sender: params[:sender_id], receiver: params[:receiver_id], fb_rating: 0})
              User.send_push_notification({user_id: params[:receiver_id], message: message})
              render json: { success: true,
                             info: 'Message sent',
                             data: { conversation_id: conversation.id },
                             status: 200 }
            else
              render json: { errors: conversation.errors.full_messages, success: false }, status: 200
            end
          else
            render json: { errors: 'You are out of radius'}
          end
        when 'ignore'
          conversation = Conversation.find(params[:conversation_id])
          if conversation
            conversation.update_attributes!(status: 'Open')
            User.send_push_notification({user_id: params[:receiver_id]})
            conversation.ignore_user(params[:sender_id], params[:receiver_id])
            render json: { success: true,
                           info: 'You now ignore this user for 1 hours' }
          else
            render json: { success: false,
                           info: 'Bad request' }
          end
      end
    end
  end

  # :nocov:
  swagger_api :conversation_detail do
    summary "Conversation detail"
    param :query, :authentication_token, :string, :required, "Authentication token"
    param :query, :conversation_id, :integer, :required, "Conversation id"
  end
  # :nocov:

  def conversation_detail
    @conversation = Conversation.find_by_id(params[:conversation_id])
    if @conversation
      @opponent = @conversation.opponent_identity(@current_user.id)
      @my_message = @conversation.my_message(@current_user.id)
      @opponent_message = @conversation.my_message(@opponent.id)
    else
      render json: { success: false,
                     info: 'Conversation not found' }
    end
  end

  # :nocov:
  swagger_api :unread_messages do
    summary "Number of unread messages"
    param :query, :authentication_token, :string, :required, "Authentication token"
  end
  # :nocov:

  def unread_messages
    messages = Conversation.unread_messages(@current_user.id)
    if messages > 0
      render json: { success: true,
                     info: 'Number of unread messages',
                     data: messages,
                     status: 200 }
    else
      render json: { success: true,
                     info: 'You have no unread messages',
                     status: 200 }
    end
  end

  # :nocov:
  swagger_api :history_of_digital_hello do
    summary "History of all digital hello"
    param :query, :authentication_token, :string, :required, "Authentication token"
  end
  # :nocov:

  def history_of_digital_hello
    @history_of_digital_hello = @current_user.conversations_history
    @fb_share = @current_user.facebook_share_rating
  end

  # :nocov:
  swagger_api :remove_conversation do
    summary "Remove conversation"
    param :query, :authentication_token, :string, :required, "Authentication token"
    param :query, :conversation_id, :integer, :required, "Conversation id"
  end
  # :nocov:

  def remove_conversation
    conversation = Conversation.find_by_id(params[:conversation_id])
    if conversation && conversation.remove_conversation(@current_user.id)
      render json: { success: true,
                     info: 'Conversation removed',
                     status: 200 }
    else
      render json: { success: true,
                     info: 'Failed',
                     status: 200 }
    end
  end

  private

  def set_user
    @conversation = Conversation.find(params[:id])
  end

  def messages_params
    params.require(:conversation).permit(:sender_id, :receiver_id, :initial, :reply, :finished, :initial_viewed,
                                         :reply_viewed, :finished_viewed, :avatar)
  end

end
