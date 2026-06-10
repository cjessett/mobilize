class ConversationsController < ApplicationController
  before_action :load_conversations, only: [ :index, :show ]

  def index
  end

  def show
    @person = Person.visible_to(current_membership).find(params[:id])
    @messages = @person.messages.order(:created_at).last(200)
  end

  def reply
    person = Person.visible_to(current_membership).find(params[:id])
    body = params.require(:message)[:body]
    if body.blank?
      redirect_to conversation_path(person), alert: "Message can't be blank."
    elsif person.opted_out_sms?
      redirect_to conversation_path(person), alert: "This person has opted out of SMS."
    else
      Message.compose!(person: person, body: body).deliver_later
      redirect_to conversation_path(person)
    end
  end

  private

  def load_conversations
    visible_people = Person.visible_to(current_membership)
    latest = Message.where(person_id: visible_people.select(:id)).group(:person_id).maximum(:created_at)
    @conversations = latest.sort_by { |_, at| at }.reverse.first(100).map do |person_id, at|
      person = Person.find(person_id)
      [ person, person.messages.order(created_at: :desc).first, at ]
    end
  end
end
