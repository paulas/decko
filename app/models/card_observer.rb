class CardObserver < ActiveRecord::Observer
  observe Card::Base

  
  def after_create(card)
    card.current_revision = Revision.create!( :card_id=>card.id, :content=>card.content)
    Renderer.instance.render( card, custom_content=false, update_references=true )
    after_content_change( card )
    card.save!
    
    # this reload fixes a weird error in wiki_reference_test/test_container_transclusion
    card.reload  
    
    Tag.update_all("card_count=card_count+1", ['id=?', card.tag_id]) unless card.simple?
    WikiReference.update_on_create(card)
    RecentChange.log( 'created', card )
  end
  
  def before_update(card)
    #warn "CHECKING UPDATE ON CARD = #{card.name}"
    # FIXME:  this check was causing remove to fail.  Apparently some update happens as the card is 
    # on the way down
    #raise(Wagn::PermissionDenied,"edit this card") unless card.edit_ok?( refresh_role = true ) 
  end
  
  def before_destroy(card)
    # check permissions  
    return if card.new_record?
    
    card.dying = true
  
    if Card::Cardtype===card and card.cards_of_this_type.length > 0
      raise Wagn::Oops, "Can't remove Cardtype #{card.extension.class_name}: cards of this type still exist"
    end
    WikiReference.update_on_destroy(card)
    # also clears references to the card
    RecentChange.log( 'removed', card)
    
    # otherwise deleting the revision fails 
    card.update_attribute(:current_revision_id, nil)
  end
  
  def after_destroy(card)
    card.dying = true
    card.tag.destroy if card.simple?
    Tag.update_all("card_count=card_count-1", ['id=?', card.tag_id]) unless card.simple?
  end
  
  def after_save(card)
    # note this isn't triggered when WagBot creates a revision, which i *think* 
    # is what we want.
    if card.just_revised? 
      RecentChange.log( 'revised', card ) 
      after_content_change( card )
    end
  end
  
  def after_content_change( card )
    if !card.simple? and card.tag.name == '*priority'
      if card.trunk.simple?
        card.trunk.tag.cards.each do |c|
          c.update_attribute(:priority, card.value) unless c.attribute_card('*priority')
        end
      end
      card.trunk.update_attribute(:priority, card.value)
    end
  end
  
  
end

