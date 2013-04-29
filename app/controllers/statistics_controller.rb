require 'csv'

# Controller for showing global statistics
class StatisticsController < ApplicationController

  layout "admin"
  before_filter :authenticate

  # Shows available statistics grouped by term
  def index
    @terms = get_available_terms()
  end


  # Shows all events for a given term. It can also be used to download
  # or view visitors stats for a given event.
  def visitors

    @term = params[:id]

    # Only fetch statistics for a specific event or when downloading statistics as an .xls file.
    if !params[:event_id].nil? || params[:format] == "xls"
      if !params[:event_id].nil?
        @event = Event.find(params[:event_id])
        @events = [@event]
      else
        @events = available_events(@term)
      end

      @visitor_stats = Event.get_visitor_stats_for_events(@term , @events)

      # Output an xls file
      send_csv(
        "besokstatistik_#{@term}.tsv",
        visitor_stats_csv(@visitor_stats)
      ) if params[:format] == "xls"
    else
      @events = available_events(@term)
    end

  end

  def questionnaires
    @term = params[:id]

    if !params[:event_id].nil?
      @event = Event.find(params[:event_id])

      if !@event.questionnaire.nil? && @event.questionnaire.answer_forms.count > 0 
        send_csv(
          "enkatstatistik_#{@term}.tsv",
          questionnaire_stats_csv(
            "Enkätsvar för #{@event.name}",
            @event.questionnaire
          )
        ) if params[:format] == "xls"
      else
        flash[:warning] = "Evenemanget saknar enkät eller enkätsvar."
        redirect_to :action => "questionnaires"
      end
    else
      @events = available_events(@term).select { |e|
        !e.questionnaire.nil? && e.questionnaire.answer_forms.count > 0
      }
    end
  end

  def unbooking_questionnaires
    @term = params[:id]
    @questionnaire = Questionnaire.find_unbooking
    from, to = term_to_date_span(@term)
    @answer_forms = @questionnaire.answer_forms.all(
      :conditions => { :created_at => from..to }
    )
    send_csv(
      "avbokningsstatistik_#{@term}.tsv",
      questionnaire_stats_csv(
        "Avbokningsenkätsvar",
        @questionnaire
      )
    ) if params[:format] == "xls"
  end


  private

  def questionnaire_stats_csv(title, questionnaire)
    res = ""
    answer_forms = questionnaire.answer_forms

    CSV.generate_row([title], 1, res, "\t")
    CSV.generate_row(["Antal besvarade enkäter", "Antal obesvarade enkäter"], 2, res, "\t")
    CSV.generate_row([answer_forms.count(:all, :conditions => { :completed => true })], 2, res, "\t" )
    CSV.generate_row([answer_forms.count(:all, :conditions => { :completed => false })], 2, res, "\t")
    CSV.generate_row([], 0, res)
    CSV.generate_row([], 0, res)
    CSV.generate_row(["Fråga", "Svar"], 2, res, "\t")

    questionnaire.questions.each do |q|
      row = []
      stat = q.statistics_for_answer_forms(answer_forms)

      case q.qtype
      when "QuestionMark"
        row = [ "#{q.question} (Genomsnittssvar)" ]
        row += [ stat[0] ]
        CSV.generate_row(row, row.length, res, "\t")
      when "QuestionText"
        row = [ "#{q.question} (Alla svar)" ]
        row += stat.reject { |s| s.blank? }
        CSV.generate_row(row, row.length, res, "\t") 
      when "QuestionBool"
        row = [ "#{q.question} (Procent ja-svar , Procent nej-svar)" ]
        row += stat
        CSV.generate_row(row, row.length, res, "\t")
      when "QuestionMchoice"
        choices = stat.keys.sort
        row = [ "#{q.question} (Antal för varje ord)" ]
        row += choices
        CSV.generate_row(row, row.length, res, "\t") 
        row = [""]
        row += choices.collect { |c| stat[c] }
        CSV.generate_row(row, row.length, res, "\t") 
      end
    end
    return res
  end

  # Returns all avaiable terms in an array
  # The format of a term is "ht|vtYYYY", e.g. ht2007 (autumn term 2007)
  # vt = vårtermin. ht = hösttermin
  def get_available_terms

    # Begins at fall 2001
    available_terms = []
    2009.upto(Date.today.year) do |year|

      num_vt = Occasion.count :all, :conditions => "date between '#{year}-01-01' and '#{year}-06-30'"
      num_ht = Occasion.count :all, :conditions => "date between '#{year}-07-01' and '#{year}-12-31'"

      available_terms << "vt#{year}" if num_vt > 0
      available_terms << "ht#{year}" if num_ht > 0

    end

    return available_terms
  end

  def term_to_date_span(term)
    term, year = term.scan(/^(vt|ht)(20[01][0-9])$/).first

    if term == 'vt'
      from = "#{year}-01-01"
      to = "#{year}-06-30"
    else
      from = "#{year}-07-01"
      to = "#{year}-12-31"
    end
    [from, to]
  end

  # Returns all available events for a given term
  # The format of a term is "ht|vtYYYY", e.g. ht2007 (autumn term 2007)
  def available_events(term)
    from, to = term_to_date_span(term)
    Event.find :all, :include => :culture_provider,
      :conditions => [ "events.id in (select event_id from occasions where occasions.date between ? and ?)", from, to ]
  end

  # Returns a comma-seperated values (CSV) string
  def visitor_stats_csv(visitor_stats)
    output_buffer = ""
    row = ["Stadsdel" , "Skola" , "Grupp" , "Föreställning" , "Antal bokade" , "Antal barn" , "Antal vuxna" ]

    CSV.generate_row(row, row.length, output_buffer, "\t")

    visitor_stats.each do |v|
      row = [ v["district_name"] , v["school_name"] ,v["group_name"] ,v["event_name"] ,v["num_booked"] ,v["num_children"] ,v["num_adult"] ]
      CSV.generate_row(row, row.length, output_buffer, "\t")
    end

    return output_buffer
  end

end
