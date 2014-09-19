class Api::ConversationsController < ApplicationController

  before_action :api_authenticate_user

  def messaging
    if Mute.where(sender_id: [params[:sender_id],params[:receiver_id]],
                  receiver_id: [params[:receiver_id],params[:sender_id]]).any?
      render json: { success: false,
                        info: 'You have been muted with this user'
                   }
    else
      case params[:type]
        when 'initial'
          conversation = Conversation.new(sender_id: params[:sender_id], receiver_id: params[:receiver_id],
                                            initial: params[:msg])
          if conversation.save
            User.rating_update({sender: params[:sender_id], receiver: params[:receiver_id]})
            User.send_push_notification({user_id: params[:receiver_id], message: params[:msg]})
            render json: { success: true,
                              info: 'Message sent',
                              data: { conversation_id: conversation.id },
                            status: 200
                         }
          else
            render json: { errors: conversation.errors.full_messages, success: false }, status: 200
          end
        when 'reply'
          conversation = Conversation.find_by_id(params[:conversation_id])
          if conversation.update_attributes(reply: params[:msg])
            User.rating_update({sender: params[:sender_id], receiver: params[:receiver_id]})
            User.send_push_notification({user_id: params[:sender_id], message: params[:msg]})
            render json: { success: true,
                              info: 'Message sent',
                              data: { conversation_id: conversation.id },
                            status: 200
                         }
          else
            render json: { errors: conversation.errors.full_messages, success: false }, status: 200
          end
        when 'finished'
          conversation = Conversation.find_by_id(params[:conversation_id])
          if conversation.update_attributes(finished: params[:msg])
            User.rating_update({sender: params[:sender_id], receiver: params[:receiver_id]})
            User.send_push_notification({user_id: params[:receiver_id], message: params[:msg]})
            render json: { success: true,
                              info: 'Message sent',
                              data: { conversation_id: conversation.id },
                            status: 200
                         }
          else
            render json: { errors: conversation.errors.full_messages, success: false }, status: 200
          end
        when 'ignore'
          conversation = Conversation.find_by_id(params[:conversation_id])
          if conversation
            # TODO: send push notification on ignore
            conversation.ignore_user(params[:sender_id], params[:receiver_id])
            render json: { success: true,
                              info: 'You now ignore this user for 4 hours'
                         }
          else
            render json: { success: false,
                              info: 'Bad request'
                         }
          end
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
