class SegmentsController < ApplicationController
  before_action :set_segment, only: [ :show, :edit, :update, :destroy ]

  def index
    @segments = Segment.visible_to(current_membership).order(:name)
  end

  def show
    @people = @segment.people.order(:first_name, :last_name).limit(200).includes(:tags)
  end

  def new
    @segment = current_organization.segments.new(access_scope: current_organization)
  end

  def create
    @segment = current_organization.segments.new(segment_attributes)
    if @segment.save
      redirect_to @segment, notice: "Segment created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @segment.update(segment_attributes)
      redirect_to @segment, notice: "Segment updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @segment.destroy
    redirect_to segments_path, notice: "Segment deleted."
  end

  private

  def set_segment
    @segment = Segment.visible_to(current_membership).find(params[:id])
  end

  def segment_attributes
    permitted = params.require(:segment).permit(:name, :match, :access_scope_gid, conditions: [ :type, :field, :op, :value, :key, :tag_id, :chapter_id ])
    conditions = Array(permitted[:conditions]).map { |c| c.to_h.compact_blank }.reject { |c| c["type"].blank? }
    {
      name: permitted[:name],
      access_scope: resolve_access_scope(permitted[:access_scope_gid]),
      definition: { "match" => permitted[:match] == "any" ? "any" : "all", "conditions" => conditions }
    }
  end

  def resolve_access_scope(gid)
    case gid
    when /\Achapter-(\d+)\z/ then current_organization.chapters.find($1)
    else current_organization
    end
  end
end
