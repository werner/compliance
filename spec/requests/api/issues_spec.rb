require 'rails_helper'
require 'helpers/api/issues_helper'
require 'json'

describe Issue do
  let(:person) { create(:empty_person) }

  def assert_issue_integrity(seed_list = [])
    Issue.count.should == 1
    Person.count.should == 1
    Issue.first.person.should == person
    seed_list.each do |seed_type|
      seed_type.constantize.count.should == 1
      seed_type.constantize.last.issue.should == Issue.first
      seed_type.constantize.last.attachments.count.should == 1
    end
  end

  def assert_replacement_issue_integrity(seed_list = [])
    Issue.count == 2
    seed_list.each do |seed_type|
      seed_type.constantize.count.should == 2
      seed_type.constantize.last.issue.should == Issue.last
      seed_type.constantize.last.attachments.count.should == 1
    end
  end

  describe 'Creating a new user Issue' do
    it 'responds with an Unprocessable Entity HTTP code (422) when body is empty' do
      post "/api/people/#{person.id}/issues",  params: {}
      assert_response 422
    end

    it 'creates a new issue with an observation' do
      reason = create(:human_world_check_reason)
      issue  = Api::IssuesHelper.issue_with_an_observation(person.id, reason, 'test')
      post "/api/people/#{person.id}/issues", params: issue
      assert_response 201
    end

    %i(png gif pdf jpg zip).each do |ext|
      describe "receives a #{ext} attachment and" do
        it 'creates a new issue with a domicile seed' do
          issue  = Api::IssuesHelper.issue_with_domicile_seed(ext)
          post "/api/people/#{person.id}/issues", params: issue
          assert_issue_integrity(["DomicileSeed"]) 
          assert_response 201
        end

        it 'creates a new issue with an identification seed' do
          issue  = Api::IssuesHelper.issue_with_identification_seed(ext)
          post "/api/people/#{person.id}/issues", params: issue
          assert_issue_integrity(["IdentificationSeed"]) 
          assert_response 201
        end

        it 'creates a new issue with a phone seed' do
          issue  = Api::IssuesHelper.issue_with_phone_seed(ext)
          post "/api/people/#{person.id}/issues", params: issue
          assert_issue_integrity(["PhoneSeed"]) 
          assert_response 201
        end

        it 'creates a new issue with an email seed' do
          issue  = Api::IssuesHelper.issue_with_email_seed(ext)
          post "/api/people/#{person.id}/issues", params: issue
          assert_issue_integrity(["EmailSeed"]) 
          assert_response 201
        end

        it 'creates a new issue with a relationship seed' do
          related_person = create(:empty_person)
          issue  = Api::IssuesHelper.issue_with_relationship_seed(related_person, ext)
          post "/api/people/#{person.id}/issues", params: issue
          Issue.count.should == 1
          Person.count.should == 2
          Issue.first.person.should == person
          RelationshipSeed.count.should == 1
          RelationshipSeed.last.issue.should == Issue.first
          RelationshipSeed.last.attachments.count.should == 1
          assert_response 201
        end

        it 'creates a new issue with an argentina invoicing seed' do
          issue  = Api::IssuesHelper.issue_with_argentina_invoicing_seed(ext)
          post "/api/people/#{person.id}/issues", params: issue
          assert_issue_integrity(["ArgentinaInvoicingDetailSeed"]) 
          assert_response 201
        end

        it 'creates a new issue with a chile invoicing seed' do
          issue  = Api::IssuesHelper.issue_with_chile_invoicing_seed(ext)
          post "/api/people/#{person.id}/issues", params: issue
          assert_issue_integrity(["ChileInvoicingDetailSeed"]) 
          assert_response 201
        end

        it 'creates a new issue with a natural docket seed' do
          issue  = Api::IssuesHelper.issue_with_natural_docket_seed(ext)
          post "/api/people/#{person.id}/issues", params: issue
          assert_issue_integrity(["NaturalDocketSeed"]) 
          assert_response 201
        end

        it 'creates a new issue with a legal entity docket seed' do
          issue  = Api::IssuesHelper.issue_with_legal_entity_docket_seed(ext)
          post "/api/people/#{person.id}/issues", params: issue
          assert_issue_integrity(["LegalEntityDocketSeed"]) 
          assert_response 201
        end

        it 'creates a new issue with a allowance seed' do
          issue  = Api::IssuesHelper.issue_with_allowance_seed(ext)
          post "/api/people/#{person.id}/issues", params: issue
          assert_issue_integrity(["AllowanceSeed"]) 
          assert_response 201
        end
      end
    end
  end

  describe 'Updating people info' do
     %i(png gif pdf jpg zip).each do |ext|
      describe "receives a #{ext} attachment and" do
        it 'creates a new issue with a domicile seed who wants to replace the current domicile' do
          full_natural_person = create(:full_natural_person)
          issue  = Api::IssuesHelper.issue_with_domicile_seed(ext)
          issue[:included][0][:relationships].merge!({
            replaces: { data: { type: 'domiciles', id: Domicile.last.id.to_s } }
          })

          post "/api/people/#{full_natural_person.id}/issues", params: issue

          assert_replacement_issue_integrity(["DomicileSeed"])
          DomicileSeed.last.replaces.should == Domicile.last
          DomicileSeed.first.replaces.should be_nil
          assert_response 201
        end

        it 'creates a new issue with an identification seed who wants to replace the current identification' do
          full_natural_person = create(:full_natural_person)
          issue  = Api::IssuesHelper.issue_with_identification_seed(ext)
          issue[:included][0][:relationships].merge!({
            replaces: { data: { type: 'identifications', id: Identification.last.id.to_s } }
          })

          post "/api/people/#{full_natural_person.id}/issues", params: issue

          assert_replacement_issue_integrity(["IdentificationSeed"])
          IdentificationSeed.last.replaces.should == Identification.last
          IdentificationSeed.first.replaces.should be_nil
          assert_response 201
        end

        it 'creates a new issue with an allowance seed who wants to replace the current allowance' do
          full_natural_person = create(:full_natural_person)
          issue  = Api::IssuesHelper.issue_with_allowance_seed(ext)
          issue[:included][0][:relationships].merge!({
            replaces: { data: { type: 'allowances', id: Allowance.last.id.to_s } }
          })

          post "/api/people/#{full_natural_person.id}/issues", params: issue

          Issue.count.should == 2 
          AllowanceSeed.count.should == 3
          AllowanceSeed.last.issue.should == Issue.last
          AllowanceSeed.last.attachments.count.should == 1
          AllowanceSeed.last.replaces.should == Allowance.last
          AllowanceSeed.first.replaces.should be_nil
          assert_response 201
        end

        it 'creates a new issue with a phone seed who wants to replace the current phone' do
          full_natural_person = create(:full_natural_person)
          issue  = Api::IssuesHelper.issue_with_phone_seed(ext)
          issue[:included][0][:relationships].merge!({
            replaces: { data: { type: 'phones', id: Phone.last.id.to_s } }
          })

          post "/api/people/#{full_natural_person.id}/issues", params: issue

          Issue.count.should == 2 
          PhoneSeed.count.should == 2
          PhoneSeed.last.issue.should == Issue.last
          PhoneSeed.last.attachments.count.should == 1
          PhoneSeed.last.replaces.should == Phone.last
          PhoneSeed.first.replaces.should be_nil
          assert_response 201
        end

        it 'creates a new issue with an email seed who wants to replace the current email' do
          full_natural_person = create(:full_natural_person)
          issue  = Api::IssuesHelper.issue_with_email_seed(ext)
          issue[:included][0][:relationships].merge!({
            replaces: { data: { type: 'emails', id: Email.last.id.to_s } }
          })

          post "/api/people/#{full_natural_person.id}/issues", params: issue

          Issue.count.should == 2 
          EmailSeed.count.should == 2
          EmailSeed.last.issue.should == Issue.last
          EmailSeed.last.attachments.count.should == 1
          EmailSeed.last.replaces.should == Email.last
          EmailSeed.first.replaces.should be_nil
          assert_response 201
        end

        it 'creates a new issue with a relationship seed who wants to replace the current relationship' do
          new_partner = create(:empty_person)
          full_natural_person = create(:full_natural_person)
          issue  = Api::IssuesHelper.issue_with_relationship_seed(new_partner, ext)
          issue[:included][0][:relationships].merge!({
            replaces: { data: { type: 'relationships', id: full_natural_person.relationships.first.id.to_s } }
          })

          post "/api/people/#{full_natural_person.id}/issues", params: issue

          Issue.count.should == 2 
          RelationshipSeed.count.should == 2
          RelationshipSeed.last.issue.should == Issue.last
          RelationshipSeed.last.replaces.should == Person.second.relationships.first
          RelationshipSeed.first.replaces.should be_nil
          assert_response 201
        end
      end
    end
  end

  describe 'Updating an issue' do
    it 'responds with 404 when issue does not exist' do
      person = create :full_natural_person
      patch "/api/people/#{person.id}/issues/#{Issue.last.id + 100}"
      assert_response 404
    end

    it 'responds with 404 when issue belongs to someone else' do
      person = create :full_natural_person
      other = create :full_natural_person
      patch "/api/people/#{person.id}/issues/#{other.issues.last.id}"
      assert_response 404
    end

    it 'responds to an observation changing the domicile' do
      post "/api/people/#{person.id}/issues",
        params: Api::IssuesHelper.issue_with_domicile_seed(:png)
      create(:observation, issue: Issue.last)
 
      assert_issue_integrity(["DomicileSeed"])

      issue_document = json_response

      issue_document[:included][1][:attributes] = {
        country: "Argentina",
        state: "Baires", 
        street_address: "Mitre",
        street_number: "6782",
        postal_code: "1341",
        floor: "1",
        apartment: "N/A"	  
      } 
      issue_document[:included][2] = {
        type: 'observations',
        id: Observation.last.id,
        attributes: {
          reply: "Mire, mejor me cambio la dirección"
        },
        relationships: {
          issue: {data: {id: Issue.last.id, type: "issues"}},
          observation_reason: {
            data: 
            {
              id: Observation.last.observation_reason.id.to_s, 
             type: "observation_reasons"
            }
          }
        }
      }

      patch "/api/people/#{person.id}/issues/#{person.issues.last.id}",
        params: JSON.dump(issue_document),
        headers: {"CONTENT_TYPE" => 'application/json' }
      assert_response 200

      DomicileSeed.first.tap do |seed|
        seed.reload
        seed.country.should == "Argentina"
        seed.state.should == "Baires"
        seed.city == "CABA"
        seed.street_address == 'Mitre'
        seed.postal_code == "1341"
        seed.floor == "1"
        seed.apartment == "N/A"
      end

      Issue.last.should be_answered
    end

    it 'responds to an observation changing the phone' do
      post "/api/people/#{person.id}/issues",
        params: Api::IssuesHelper.issue_with_phone_seed(:png)
      create(:observation, issue: Issue.last)
 
      assert_issue_integrity(["PhoneSeed"])

      issue_document = json_response

      issue_document[:included][1][:attributes] = {
        number: "+571165342178",
        kind: "cellphone", 
        country: "Colombia",
        has_whatsapp: true,
        has_telegram: false,
        note: "Please use whatsapp"
      } 
      issue_document[:included][2] = {
        type: 'observations',
        id: Observation.last.id,
        attributes: {
          reply: "Mire, mi nuevo telefono"
        },
        relationships: {
          issue: {data: {id: Issue.last.id, type: "issues"}},
          observation_reason: {
            data: 
            {
              id: Observation.last.observation_reason.id.to_s, 
             type: "observation_reasons"
            }
          }
        }
      }

      patch "/api/people/#{person.id}/issues/#{person.issues.last.id}",
        params: JSON.dump(issue_document),
        headers: {"CONTENT_TYPE" => 'application/json' }
      assert_response 200

      PhoneSeed.first.tap do |seed|
        seed.reload
        seed.number.should == "+571165342178"
        seed.kind.should == "cellphone"
        seed.country.should == "Colombia"
        seed.has_whatsapp.should == true
        seed.has_telegram.should == false
        seed.note.should == "Please use whatsapp"
      end

      Issue.last.should be_answered
    end

    it 'can answer an observation and add a new one in one step' do
      person = create :new_natural_person
      issue = person.issues.last
      create :robot_observation, issue: issue

      get "/api/people/#{person.id}/issues/#{issue.id}"
      issue_request = json_response

      observation = Api::IssuesHelper.observation_for(
        issue.id, create(:human_world_check_reason), "Run manually")

      issue_request[:included]
        .find{|i| i[:type] == 'observations'}[:attributes] = { reply: "hits" }
        
      issue_request[:data][:relationships][:observations][:data] <<
        observation.slice(:id, :type)

      issue_request[:included] << observation

      patch "/api/people/#{person.id}/issues/#{issue.id}", 
        params: issue_request.to_json,
        headers: {"CONTENT_TYPE" => 'application/json'}

      api_response.data.attributes.state.should == "observed"
      observations = api_response.included.select{|i| i.type == 'observations' }
      observations.count.should == 2
      observations.map{|o| o.attributes.state }.should == %w(answered new)
    end
  end

  describe 'Getting an issue' do
    it 'responds with a not found error 404 when the issue does not exist' do
      get "/api/people/#{person.id}/issues/1"
      assert_response 404
    end

    it 'shows all the person info when the issue exist' do  
      issue  = Api::IssuesHelper.issue_with_domicile_seed(:png)
      post "/api/people/#{person.id}/issues", params: issue
      response_for_post = response.body

      assert_issue_integrity(["DomicileSeed"])
  
      get  "/api/people/#{person.id}/issues/#{Issue.first.id}"
      assert_response 200
      response.body.should == response_for_post
    end
  end
end
