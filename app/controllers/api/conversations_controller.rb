class Api::ConversationsController < ApplicationController

  before_action :api_authenticate_user

  def messaging
    case params[:type]
      when 'initial'
        conversation = Conversation.new(sender_id: params[:sender_id], receiver_id: params[:receiver_id],
                                        initial: params[:msg])
        if conversation.save
          render json: {success: true,
                        info: 'Message sent',
                        data: conversation.id,
                        status: 200
          }
        else
          render json: {errors: conversation.errors.full_messages, success: false}, status: 200
        end
      when 'reply'
        conversation = Conversation.find_by_id(params[:conversation_id])
        if conversation.update_attributes(reply: params[:msg])
          render json: {success: true,
                        info: 'Message sent',
                        data: conversation.id,
                        status: 200
          }
        else
          render json: {errors: message.errors.full_messages, success: false}, status: 200
        end
      when 'finished'
        conversation = Conversation.find_by_id(params[:conversation_id])
        if conversation.update_attributes(finished: params[:msg])
          render json: {success: true,
                        info: 'Message sent',
                        data: conversation.id,
                        status: 200
          }
        else
          render json: {errors: message.errors.full_messages, success: false}, status: 200
        end
    end

  end

  def unread_messages
    if @current_user
      unread_messages = @current_user.conversations_my.where("initial_viewed = false or reply_viewed = false or finished_viewed = false").select("initial_viewed, reply_viewed, finished_viewed")
      as = unread_messages.select{|u| u.initial_viewed == false}.count
      as += unread_messages.select{|u| u.reply_viewed == false}.count
      as += unread_messages.select{|u| u.finished_viewed == false}.count
      puts unread_messages
      if unread_messages
        render json: {success: true,
                      info: 'Here is the list of all your unread messages',
                      data: as,
                      status: 200
        }
      else
        render json: {success: true,
                      info: 'You have no unread messages',
                      status: 200
        }
      end
    end
  end

  private

  def set_user
    @conversation = Conversation.find(params[:id])
  end

  def messages_params
    params.require(:conversation).permit(:sender_id, :receiver_id, :initial, :reply, :finished, :initial_viewed,
                                         :reply_viewed, :finished_viewed)
  end

end

