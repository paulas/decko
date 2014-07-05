# -*- encoding : utf-8 -*-

include Wagn::Location
describe Card::Set::Type::Signup do
  
  before do
    Card::Auth.current_id = Card::AnonymousID
  end
  
  
  context 'signup form form' do
    before do
      card = Card.new :type_id=>Card::SignupID
      @form = card.format.render_new
    end
    
    it 'should prompt to signup' do
      Card::Auth.as :anonymous do
        @form.match( /Sign up/ ).should be_true
      end
    end
  end
  

   
  context 'signup (without approval)' do
    before do
      ActionMailer::Base.deliveries = [] #needed?
      Card::Auth.as_bot do
        Card.create! :name=>'User+*type+*create', :content=>'[[Anyone]]'
        Card.create! :name=>'*request+*to', :content=>'signups@wagn.org'

      end
      @signup = Card.create! :name=>'Big Bad Wolf', :type_id=>Card::SignupID, '+*account'=>{'+*email'=>'wolf@wagn.org',
         '+*password'=>'wolf'}     
      @account = @signup.account
      @token = @account.token
    end
    
    it 'should create all the necessary cards' do
      @signup.type_id.should == Card::SignupID
      @account.email.should == 'wolf@wagn.org'
      @account.status.should == 'pending'
      @account.salt.should_not == ''
      @account.password.length.should > 10 #encrypted
      @account.token.should be_present
    end
  
    it 'should send email with an appropriate link' do
      @mail = ActionMailer::Base.deliveries.last
      expect( @mail.body.raw_source ).to match(Card.setting( :title ))
    end
    
    it 'should create an authenticable token' do
      Card::Auth.authenticate_by_token(@token).should == @signup.id
    end
    
    it 'should notify someone' do
      ActionMailer::Base.deliveries.last.to.should == ['signups@wagn.org']
    end
    
    it 'should be activated by an update' do
      Card::Env.params[:token] = @token
      @signup.update_attributes({})
      #puts @signup.errors.full_messages * "\n"
      @signup.errors.should be_empty
      @signup.type_id.should == Card::UserID
      @account.status.should == 'active'
      Card[ @account.name ].active?.should be_true
    end
    
    it 'should reject expired token and create new token' do
      @account.token_card.update_column :updated_at, 3.days.ago.strftime("%F %T")
      @account.token_card.expire
      Card::Env.params[:token] = @token
      
      result = @signup.update_attributes!({})
      result.should == true                 # successfully completes save
      @account.token.should_not == @token   # token gets updated
      success = Card::Env.params[:success]
      success[:message].should =~ /expired/ # user notified of expired token
    end
  
  end


  context 'signup (with approval)' do
    before do
      # NOTE: by default Anonymous does not have permission to create User cards.
      Card::Auth.as_bot do
        Card.create! :name=>'*request+*to', :content=>'signups@wagn.org'
      end
      @signup = Card.create! :name=>'Big Bad Wolf', :type_id=>Card::SignupID, '+*account'=>{ 
        '+*email'=>'wolf@wagn.org', '+*password'=>'wolf'
      }
      @account = @signup.account
    end
    
    
    it 'should create all the necessary cards, but no token' do
      @signup.type_id.should == Card::SignupID
      @account.email.should == 'wolf@wagn.org'
      @account.status.should == 'pending'
      @account.salt.should_not == ''
      @account.password.length.should > 10 #encrypted
    end
    
    it 'should not create a token' do
      @account.token.should_not be_present
    end
    
    it 'should notify someone' do
      ActionMailer::Base.deliveries.last.to.should == ['signups@wagn.org']
    end
    
    context 'approval' do
      before do
        Card::Env.params[:approve] = true
        Card::Auth.as :joe_admin
      end
      
      it 'should create token' do
        @signup = Card.fetch @signup.id
        @signup.save!
        @signup.account.token.should be_present
      end
    end

  end

  # describe '#signup_notifications' do
  #   before do
  #     Card::Auth.as_bot do
  #       Card.create! :name=>'*request+*to', :content=>'signups@wagn.org'
  #     end
  #     @user_name = 'Big Bad Wolf'
  #     @user_email = 'wolf@wagn.org'
  #     @signup = Card.create! :name=>@user_name, :type_id=>Card::SignupID, '+*account'=>{
  #       '+*email'=>@user_email, '+*password'=>'wolf'}
  #     ActionMailer::Base.deliveries = []
  #     @signup.signup_notifications
  #     @mail = ActionMailer::Base.deliveries.last
  #   end
  #
  #   it 'send to correct address' do
  #     expect(@mail.to).to eq(['signups@wagn.org'])
  #   end
  #
  #   it 'contains request url' do
  #      expect(@mail.body.raw_source).to include(wagn_url(@signup))
  #   end
  #
  #   it 'contains user name' do
  #     expect(@mail.body.raw_source).to include(@user_name)
  #   end
  #
  #   it 'contains user email' do
  #     expect(@mail.body.raw_source).to include(@user_email)
  #   end
  # end
end
