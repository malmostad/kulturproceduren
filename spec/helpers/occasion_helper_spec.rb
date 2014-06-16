require "spec_helper"

describe OccasionHelper do
  describe "#booking_link" do
    let(:user_online) { false }
    let(:current_user) { nil }

    let(:event) { create(:bookable_event, _tickets: 5) }
    let(:occasion) { create(:occasion, event: event) }

    before(:each) do
      helper.stub(:user_online?).and_return(user_online)
      helper.stub(:current_user).and_return(current_user)
    end

    context "not online" do
      context "with a bookable event" do
        it "links to the login page" do
          expect(helper.booking_link(occasion)).to have_css("a[href^='/login']")
        end
      end
      context "with a non-bookable event" do
        let(:event) { create(:event) }
        it "links to the event" do
          expect(helper.booking_link(occasion)).to have_css("a[href='/events/#{event.id}']")
        end
      end
    end
    context "online without booking privileges" do
      let(:user_online) { true }
      let(:current_user) { double(:user, can_book?: false) }
      it "displays nothing" do
        expect(helper.booking_link(occasion)).to be_blank
      end
    end
    context "with booking privileges" do
      let(:user_online) { true }
      let(:current_user) { double(:user, can_book?: true) }

      context "with a non-bookable event" do
        let(:event) { create(:event) }
        it "does not show a link" do
          expect(helper.booking_link(occasion)).to be_blank
        end
      end
      context "with an occasion with available seats" do
        it "links to the booking" do
          expect(helper.booking_link(occasion)).to have_css("a[href='/occasions/#{occasion.id}/bookings/new']")
        end
        it "includes the available seats in the title" do
          expect(helper.booking_link(occasion)).to have_css("a[title='5 lediga platser']")
        end
      end
      context "with a sold out occasion" do
        let(:occasion) { create(:occasion, event: event, seats: 0, wheelchair_seats: 0) }
        it "shows a sold out indicator" do
          expect(helper.booking_link(occasion)).to have_css("span.sold-out")
        end
      end
      context "with a sold out event" do
        before(:each) do
          event.tickets.each do |t|
            t.state = :booked
            t.save!
          end
        end
        it "shows a sold out indicator" do
          expect(helper.booking_link(occasion)).to have_css("span.sold-out")
        end
      end
    end
  end

  describe "#ticket_availability_link" do
    let(:user_online) { false }
    let(:current_user) { nil }

    let(:event) { create(:bookable_event, _tickets: 5) }
    let(:occasion) { create(:occasion, event: event) }

    before(:each) do
      helper.stub(:user_online?).and_return(user_online)
      helper.stub(:current_user).and_return(current_user)
    end

    context "with an offline user" do
      it "is blank" do
        expect(helper.ticket_availability_link(occasion)).to be_blank
      end
    end
    context "without booking privileges" do
      let(:user_online) { true }
      let(:current_user) { double(:user, can_book?: false) }
      it "is blank" do
        expect(helper.ticket_availability_link(occasion)).to be_blank
      end
    end
    context "with an event that's not bookable" do
      let(:user_online) { true }
      let(:current_user) { double(:user, can_book?: true) }
      let(:event) { create(:event) }
      it "is blank" do
        expect(helper.ticket_availability_link(occasion)).to be_blank
      end
    end
    context "with booking privileges and a bookable event" do
      let(:user_online) { true }
      let(:current_user) { double(:user, can_book?: true) }
      it "links to the ticket availability page" do
        expect(helper.ticket_availability_link(occasion)).to have_css("a[href='/occasions/#{occasion.id}/ticket_availability']")
      end
      it "displays the link as an info icon" do
        expect(helper.ticket_availability_link(occasion)).to have_css("img[src='/images/information.png']")
      end
      it "includes info about the event in the title" do
        expect(helper.ticket_availability_link(occasion)).to have_css("a[title$='#{occasion.event.name} #{occasion.date} #{l occasion.start_time, format: :only_time}']")
      end
    end
  end
end
