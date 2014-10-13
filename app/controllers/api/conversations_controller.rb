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
    if Mute.where(sender_id: [params[:sender_id],params[:receiver_id]],
                  receiver_id: [params[:receiver_id],params[:sender_id]]).any?
      render json: { success: false,
                     info: 'You have been muted with this user' }
    else
      message = "#{@current_user.user_name} : #{params[:msg]}"
      case params[:type]
        when 'initial'
          conversation = Conversation.new(sender_id: params[:sender_id], receiver_id: params[:receiver_id],
                                          initial: params[:msg], status: 'Closed')
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
          if @current_user.in_radius?(params[:sender_id])
            conversation = Conversation.find(params[:conversation_id])
            if conversation.update_attributes!(reply: params[:msg], reply_viewed: 0)
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
            @current_user.place_to_pending(params[:conversation_id], params[:sender_id])
            render json: { errors: 'You are out of radius'}
          end
        when 'finished'
          if @current_user.in_radius?(params[:receiver_id])
            conversation = Conversation.find(params[:conversation_id])
            if conversation.update_attributes!(finished: params[:msg], finished_viewed: false, status: 'Open')
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
    conversation = Conversation.find(params[:conversation_id])

    if conversation
      conversation.update_attributes!(conversation.existing_messages)
      render json: { success: true,
                     data: conversation.check_if_sender(@current_user.id),
                     conversation_id: params[:conversation_id] }
    else
      render json: { success: false,
                     info: 'No such conversation' }
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
    conv_arel = Conversation.arel_table
    history = Conversation.where(conv_arel[:sender_id].eq(@current_user.id).or(conv_arel[:receiver_id].eq(@current_user.id)))

    if history
      render json: { success: true,
                     data: Hash[history.each_with_index.map{|h,i| ["conversation#{i}", h.to_json(@current_user.id)]}],
                     fb_share: @current_user.facebook_share_rating,
                     status: 200 }
    else
      render json: { success: false,
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
