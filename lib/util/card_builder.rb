module CardBuilderMethods
  ## ug
  ADMIN_ID = 1

  def newcard(name, content="")
    ::Card::Basic.create(:name=>name, :content=>content)
  end
  
  def card_content( cardname )
    render(Card.find_by_name(cardname))
  end      

  def create_cards( card_names )
    card_names.collect {|name| create_compound( name ) }
  end
  
  def create_compound( name )
    create_compound_from_list( name.split('+').reverse )
  end

  def create_users( user_names )
    user_names.collect {|name| create_user(name) }
  end
  
  def create_roles( role_names )
    role_names.collect {|name| Card::Role.create( :name=>name ).extension }
  end

  def create_user( username )
    #username = separate_wikiword(username)
    raise( "invalid username" ) if username.nil? or username.empty?
    if u = User.find_by_login(username) 
      return u      
    elsif c = Card::User.find_by_name(username)
      return c.extension
    else
      u = User.create!(
        :password=>'foofoo',
        :password_confirmation=>'foofoo',
        :email=>"#{username.gsub(/\s+/,'')}@grasscommons.org",
        :login=>username, 
        :blocked => true,
        :invite_sender_id=>ADMIN_ID  
      )

      if c = Card.find_by_name(username)
        if c.type=='Basic'
          c.type='User'
        else
          raise "Can't create user card for #{username}: already points to different user"
        end
      else 
        c = Card::User.create!( :name=>username )
      end
      c.extension = u
      c.save
      return u
    end
  end      
    
   
  def admin
    User.find(ADMIN_ID)
  end
  
  def as(admin)
    tmpuser, User.current_user = User.current_user, admin
    yield
    User.current_user = tmpuser
  end

  private

  def create_compound_from_list( list )
    tag = find_or_create_by_name( list.shift )
    return tag if list.empty?
    trunk = create_compound_from_list( list )
    combo = find_or_connect( trunk, tag )
  end
  
  def find_or_connect( trunk, tag )
    (c = Card.find_by_name( "#{trunk.name}+#{tag.name}" )) ? c : trunk.connect!(tag)
  end
  
  def find_or_create_by_name( name )
    (c = Card.find_by_name( name )) ? c : ::Card::Basic.create(:name=>name, :content=>"")
  end
  
  
end


class CardBuilder
  include CardBuilderMethods
  
  def initialize
  end
  
end



