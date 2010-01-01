class SetStarLayout < ActiveRecord::Migration
  def self.up 
    User.as(:wagbot) do
      card = Card.find_or_create :name=>"*layout", :type=>"Pointer"
      if card.revisions.map(&:author).map(&:login).uniq == ["wagbot"]
        card.content =<<CONTENT

CONTENT
        card.permit('edit',Role[:admin])
        card.permit('delete',Role[:admin])
        card.save!
      end
    end
  end

  def self.down
  end
end
