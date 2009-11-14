require File.expand_path('spec_helper', File.dirname(__FILE__))

require 'nokogiri'

shared_examples_for "session" do
  def extract_results(session)
    YAML.load Nokogiri::HTML(session.body).xpath("//pre[@id='results']").first.text
  end
  
  describe '#app' do
    it "should remember the application" do
      @session.app.should == TestApp
    end
  end

  describe '#visit' do
    it "should fetch a response from the driver" do
      @session.visit('/')
      @session.body.should include('Hello world!')
      @session.visit('/foo')
      @session.body.should include('Another World')
    end
  end
  
  describe '#click_link' do
    before do
      @session.visit('/with_html')
    end

    context "with id given" do
      it "should take user to the linked page" do
        @session.click_link('foo')
        @session.body.should include('Another World')
      end
    end
    
    context "with text given" do
      it "should take user to the linked page" do
        @session.click_link('labore')
        @session.body.should include('<h1>Bar</h1>')
      end
    end

    context "with title given" do
      it "should take user to the linked page" do
        @session.click_link('awesome title')
        @session.body.should include('<h1>Bar</h1>')
      end
    end

    context "with a locator that doesn't exist" do
      it "should raise an error" do
        running do
          @session.click_link('does not exist')
        end.should raise_error(Webcat::ElementNotFound)
      end
    end

    it "should follow redirects" do
      @session.click_link('Redirect')
      @session.body.should include('You landed')
    end
  end

  describe '#click_button' do
    before do
      @session.visit('/form')
    end

    context "with value given on a submit button" do
      before do
        @session.click_button('awesome')
        @results = extract_results(@session)
      end

      it "should serialize and submit text fields" do
        @results['first_name'].should == 'John'
      end

      it "should serialize and submit password fields" do
        @results['password'].should == 'seeekrit'
      end

      it "should serialize and submit hidden fields" do
        @results['token'].should == '12345'
      end

      it "should not serialize fields from other forms" do
        @results['middle_name'].should be_nil
      end

      it "should submit the button that was clicked, but not other buttons" do
        @results['awesome'].should == 'awesome'
        @results['crappy'].should be_nil
      end

      it "should serialize radio buttons" do
        @results['gender'].should == 'female'
      end

      it "should serialize check boxes" do
        @results['pets'].should include('dog', 'hamster')
        @results['pets'].should_not include('cat')
      end

      it "should serialize text areas" do
        @results['description'].should == 'Descriptive text goes here'
      end

      it "should serialize select tag with values" do
        @results['locale'].should == 'en'
      end

      it "should serialize select tag without values" do
        @results['region'].should == 'Norway'
      end

      it "should serialize first option for select tag with no selection" do
        @results['city'].should == 'London'
      end

      it "should not serialize a select tag without options" do
        @results['tendency'].should be_nil 
      end
    end

    context "with id given on a submit button" do
      it "should submit the associated form" do
        @session.click_button('awe123')
        extract_results(@session)['first_name'].should == 'John'
      end
    end

    context "with value given on an image button" do
      it "should submit the associated form" do
        @session.click_button('okay')
        extract_results(@session)['first_name'].should == 'John'
      end
    end

    context "with id given on an image button" do
      it "should submit the associated form" do
        @session.click_button('okay556')
        extract_results(@session)['first_name'].should == 'John'
      end
    end

    it "should follow redirects" do
      @session.click_button('Go FAR')
      @session.body.should include('You landed')
    end
  end

  describe "#fill_in" do
    before do
      @session.visit('/form')
    end
    
    it "should fill in a text field by id" do
      @session.fill_in('form_first_name', :with => 'Harry')
      @session.click_button('awesome')
      extract_results(@session)['first_name'].should == 'Harry'
    end

    it "should fill in a text field by label" do
      @session.fill_in('First Name', :with => 'Harry')
      @session.click_button('awesome')
      extract_results(@session)['first_name'].should == 'Harry'
    end

    it "should fill in a textarea by id" do
      @session.fill_in('form_description', :with => 'Texty text')
      @session.click_button('awesome')
      extract_results(@session)['description'].should == 'Texty text'
    end

    it "should fill in a textarea by label" do
      @session.fill_in('Description', :with => 'Texty text')
      @session.click_button('awesome')
      extract_results(@session)['description'].should == 'Texty text'
    end

    it "should fill in a password field by id" do
      pending "Culerity doesn't like password fields for some reason" if @session.mode == :culerity
      @session.fill_in('form_password', :with => 'supasikrit')
      @session.click_button('awesome')
      extract_results(@session)['password'].should == 'supasikrit'
    end

    it "should fill in a password field by label" do
      pending "Culerity doesn't like password fields for some reason" if @session.mode == :culerity
      @session.fill_in('Password', :with => 'supasikrit')
      @session.click_button('awesome')
      extract_results(@session)['password'].should == 'supasikrit'
    end
  end

  describe "#choose" do
    before do
      @session.visit('/form')
    end
    
    it "should choose a radio button by id" do
      @session.choose("gender_male")
      @session.click_button('awesome')
      extract_results(@session)['gender'].should == 'male'
    end
    
    it "should choose a radio button by label" do
      @session.choose("Both")
      @session.click_button('awesome')
      extract_results(@session)['gender'].should == 'both'
    end
  end

  describe "#check" do
    before do
      @session.visit('/form')
    end
    
    it "should check a checkbox by id" do
      @session.check("form_pets_cat")
      @session.click_button('awesome')
      extract_results(@session)['pets'].should include('dog', 'cat', 'hamster')
    end
    
    it "should check a checkbox by label" do
      @session.check("Cat")
      @session.click_button('awesome')
      extract_results(@session)['pets'].should include('dog', 'cat', 'hamster')
    end
  end

  describe "#uncheck" do
    before do
      @session.visit('/form')
    end
    
    it "should uncheck a checkbox by id" do
      pending "Culerity doesn't seem to uncheck this" if @session.mode == :culerity
      @session.uncheck("form_pets_hamster")
      @session.click_button('awesome')
      extract_results(@session)['pets'].should include('dog')
      extract_results(@session)['pets'].should_not include('hamster')
    end
    
    it "should uncheck a checkbox by label" do
      pending "Culerity doesn't seem to uncheck this" if @session.mode == :culerity
      @session.uncheck("Hamster")
      @session.click_button('awesome')
      extract_results(@session)['pets'].should include('dog')
      extract_results(@session)['pets'].should_not include('hamster')
    end
  end

  describe "#select" do
    before do
      @session.visit('/form')
    end
    
    it "should select an option from a select box by id" do
      @session.select("Finish", :from => 'form_locale')
      @session.click_button('awesome')
      extract_results(@session)['locale'].should == 'fi'
    end
    
    it "should select an option from a select box by label" do
      @session.select("Finish", :from => 'Locale')
      @session.click_button('awesome')
      extract_results(@session)['locale'].should == 'fi'
    end
  end
  
  describe '#has_content?' do
    it "should be true if the given content is on the page at least once" do
      @session.visit('/with_html')
      @session.should have_content('est')
      @session.should have_content('Lorem')
      @session.should have_content('Redirect')
    end
    
    it "should be false if the given content is not on the page" do
      @session.visit('/with_html')
      @session.should_not have_content('xxxxyzzz')
      @session.should_not have_content('monkey')
    end
  end

  describe "#attach_file" do
    before do
      @session.visit('/form')
    end
    
    context "with normal form" do
      it "should set a file path by id" do
        @session.attach_file "form_image", __FILE__
        @session.click_button('awesome')
        extract_results(@session)['image'].should == File.basename(__FILE__)
      end

      it "should set a file path by label" do
        @session.attach_file "Image", __FILE__
        @session.click_button('awesome')
        extract_results(@session)['image'].should == File.basename(__FILE__)
      end
    end

    context "with multipart form" do
      before do
        @test_file_path = File.expand_path('fixtures/test_file.txt', File.dirname(__FILE__))
      end
      
      it "should set a file path by id" do
        @session.attach_file "form_document", @test_file_path
        @session.click_button('Upload')
        @session.body.should include(File.read(@test_file_path))
      end

      it "should set a file path by label" do
        @session.attach_file "Document", @test_file_path
        @session.click_button('Upload')
        @session.body.should include(File.read(@test_file_path))
      end
    end

  end
end
  
describe Webcat::Session do
  context 'with non-existant driver' do
    it "should raise an error" do
      running {
        Webcat::Session.new(:quox, TestApp).driver
      }.should raise_error(Webcat::DriverNotFoundError)
    end
  end
end
