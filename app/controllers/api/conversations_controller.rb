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

  def conversation_detail
    if @current_user
      conversation = Conversation.find_by_id(params[:conversation_id])
      if conversation
        render json: { success: true,
                          data: { initial: conversation.initial,
                                    reply: conversation.reply,
                                 finished: conversation.finished,
                                   ignore: conversation.ignored
                                }

                     }
        conversation.update_attributes(initial_viewed: true, reply_viewed: true, finished_viewed: true)
      else
        render json: { success: false,
                          info: 'No such conversation'
                     }
      end
    end
  end

  def unread_messages
    if @current_user
      unread_messages = @current_user.sent_messages.where("initial_viewed = false or reply_viewed = false or finished_viewed = false").select("initial_viewed, reply_viewed, finished_viewed")
      messages = unread_messages.select{|u| u.initial_viewed == false}.count
      messages += unread_messages.select{|u| u.reply_viewed == false}.count
      messages += unread_messages.select{|u| u.finished_viewed == false}.count
      if unread_messages
        render json: { success: true,
                          info: 'Number of unread messages',
                          data: messages,
                        status: 200
                     }
      else
        render json: { success: true,
                          info: 'You have no unread messages',
                        status: 200
                     }
      end
    end
  end

  def history_of_digital_hello
    if @current_user
      history = Conversation.where(sender_id: @current_user.id,
                                   receiver_id: @current_user.id)
      if history
        render json: { success: true,
                          data: Hash[history.each_with_index.map{|h,i| ["conversation#{i}", h.to_json(@current_user)]}],
                        status: 200
                     }
      else
        render json: { success: false,
                          info: 'Failed',
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
                                         :reply_viewed, :finished_viewed, :avatar)
  end

end