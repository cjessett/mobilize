class NotesController < ApplicationController
  def create
    person = Person.visible_to(current_membership).find(params[:person_id])
    note = person.notes.new(body: params.require(:note)[:body], user: Current.user)
    if note.save
      redirect_to person, notice: "Note added."
    else
      redirect_to person, alert: note.errors.full_messages.to_sentence
    end
  end
end
