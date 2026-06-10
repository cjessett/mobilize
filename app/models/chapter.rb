class Chapter < ApplicationRecord
  belongs_to :organization
  has_many :chapter_zip_codes, dependent: :destroy
  has_many :chapter_memberships, dependent: :destroy
  has_many :people, through: :chapter_memberships

  validates :name, presence: true
  normalizes :phone_number, with: ->(value) { PhoneNumber.normalize(value) }

  def zip_codes_list
    chapter_zip_codes.order(:zip_code).pluck(:zip_code)
  end

  def zip_codes_list=(zips)
    zips = zips.split(/[\s,]+/) if zips.is_a?(String)
    @pending_zip_codes = zips.map { |z| z.to_s.strip[0, 5] }.reject(&:blank?).uniq
  end

  after_save :sync_zip_codes

  private

  def sync_zip_codes
    return if @pending_zip_codes.nil?

    chapter_zip_codes.where.not(zip_code: @pending_zip_codes).destroy_all
    @pending_zip_codes.each { |zip| chapter_zip_codes.find_or_create_by!(zip_code: zip) }
    @pending_zip_codes = nil
  end
end
