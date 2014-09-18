class Api::ConversationsController < ApplicationController

  before_action :api_authenticate_user
  swagger_controller :conversations, "Conversation Management"

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
            render json: { success: true,
                              info: 'Message sent',
                              data: { conversation_id: conversation.id },
                            status: 200
                         }
          else
            render json: { errors: conversation.errors.full_messages, success: false }, status: 200
          end
        when 'reply'
          conversation = Conversation.find(params[:conversation_id])
          if conversation.update_attributes!(reply: params[:msg])
            render json: { success: true,
                              info: 'Message sent',
                              data: { conversation_id: conversation.id },
                            status: 200
                         }
          else
            render json: { errors: conversation.errors.full_messages, success: false }, status: 200
          end
        when 'finished'
          conversation = Conversation.find(params[:conversation_id])
          if conversation.update_attributes!(finished: params[:msg])
            User.rating_update({sender: params[:sender_id], receiver: params[:receiver_id]})

            render json: { success: true,
                              info: 'Message sent',
                              data: { conversation_id: conversation.id },
                            status: 200
                         }
          else
            render json: { errors: conversation.errors.full_messages, success: false }, status: 200
          end
        when 'ignore'
          conversation = Conversation.find(params[:conversation_id])
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

  swagger_api :messaging do
    summary "Messaging between users"
    param :query, :authentication_token, :string, :required, "Authentication token"
    param :query, :sender_id, :integer, :required, "Sender id"
    param :query, :receiver_id, :integer, :required, "Receiver id"
    param :query, :type, :string, :required, "Message type: initial/reply/finished/ignore"
    param :query, :msg, :string, :required, "Message"
    param :query, :conversation_id, :integer, :required, "Conversation id. Receives after type:initial, and required for other types"
  end

  def conversation_detail

    conversation = Conversation.find(params[:conversation_id])

    if conversation
      render json: { success: true,
                        data:  conversation.check_if_sender(@current_user.id),
                        conversation_id: params[:conversation_id],


                   }
      conversation.update_attributes!(initial_viewed: true, reply_viewed: true, finished_viewed: true)
    else
      render json: { success: false,
                        info: 'No such conversation'
                   }
    end

  end

  swagger_api :conversation_detail do
    summary "Conversation detail"
    param :query, :authentication_token, :string, :required, "Authentication token"
    param :query, :conversation_id, :integer, :required, "Conversation id"
  end

  def unread_messages

    sent = Conversation.select('COUNT(reply_viewed) AS reply').where("reply_viewed = false AND sender_id = #{@current_user.id}")
    received = Conversation.select("COUNT(initial_viewed) AS initial,COUNT(finished_viewed) AS finished").where("initial_viewed = false OR finished_viewed = false AND receiver_id = #{@current_user.id}")
    puts sent
    puts received
    data = sent.first[:reply] + received.first[:initial] + received.first[:finished]
    puts data
    if data > 0
       render json: { success: true,
                         info: 'Number of unread messages',
                         data: data,
                       status: 200
                    }
    else
       render json: { success: true,
                         info: 'You have no unread messages',
                       status: 200
                    }
    end

  end

  swagger_api :unread_messages do
    summary "Number of unread messages"
    param :query, :authentication_token, :string, :required, "Authentication token"
  end

  def history_of_digital_hello

    conv_arel = Conversation.arel_table

    history = Conversation.where(conv_arel[:sender_id].eq(@current_user.id).or(conv_arel[:receiver_id].eq(@current_user.id)))

    if history
      render json: { success: true,
                        data: Hash[history.each_with_index.map{|h,i| ["conversation#{i}", h.to_json(@current_user.id)]}],
                      status: 200
                   }
    else
      render json: { success: false,
                        info: 'Failed',
                      status: 200
                   }
    end

  end

  swagger_api :history_of_digital_hello do
    summary "History of all digital hello"
    param :query, :authentication_token, :string, :required, "Authentication token"
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