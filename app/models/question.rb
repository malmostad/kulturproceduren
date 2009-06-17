class Question < ActiveRecord::Base

  QTYPES = {"Betygssvar" => "QuestionMark", "Fritextsvar" => "QuestionText", "Ja/Nej svar"=> "QuestionBool" , "Flervalsvar" => "QuestionMchoice"}
  BLABB = 3
  GRAPH_WIDTH = 500
  has_and_belongs_to_many :questionaire 
  has_one                 :answer

  def self.question_to_graph(q,o)
    ans = Answer.find_by_sql( [
        "SELECT a.id,a.question_id,a.answer,a.answer_text,a.answer_form_id,a.created_at,a.updated_at
         FROM answers a , answer_forms b
         WHERE a.answer_form_id = b.id AND b.occasion_id = ? AND a.question_id = ?" , o.id , q.id ] )

    case q.qtype
    when "QuestionBool"
        n = 0
        y = 0
        ans.each do |a|
          if a.answer_text == "y"
            y += 1
          elsif a.answer_text == "n"
            n += 1
          else
            puts "AAAAAAAAAAAAARRRRRRRRRRRRRRGGGHHHHHH"
          end
        end
        g = Gruff::Pie.new(GRAPH_WIDTH)
        g.font = "/Library/Fonts/Arial.ttf"
        g.right_margin = 10
        g.left_margin = 10
        g.title_font_size = 30
        g.title = q.question.to_s
        g.sort = false
        g.data "Ja" , y
        g.data "Nej" , n
    when "QuestionMchoice"
      vals = {}
      if ans.length > 0
        keys = YAML.load(ans[0].answer_text).keys
        ans.each do |a|
          YAML.load(a.answer_text).keys.each do |k|
            if vals["#{k}"].blank?
              vals["#{k}"] = 1
            else
              vals["#{k}"] += 1
            end
          end
        end
      end
      g = Gruff::Bar.new(GRAPH_WIDTH)
      g.font = "/Library/Fonts/Arial.ttf"
      g.right_margin = 10
      g.left_margin = 10
      g.title_font_size = 30
      g.title = q.question.to_s
      g.sort = false
      vals.keys.each { |k| g.data k , vals["#{k}"].to_i }
      g.minimum_value = 0
      pp vals
    when "QuestionText"
      g = Gruff::Bar.new(GRAPH_WIDTH)
      g.font = "/Library/Fonts/Arial.ttf"
      g.right_margin = 10
      g.left_margin = 10
      g.title_font_size = 30
      g.title = q.question.to_s
      g.sort = false
    when "QuestionMark"
      histogram = []
      (0..3).each { |i| histogram[i] = 0 }
      ans.each  { |a| histogram[a.answer_text.to_i] += 1 }
      g = Gruff::Bar.new(GRAPH_WIDTH)
      g.font = "/Library/Fonts/Arial.ttf"
      g.right_margin = 10
      g.left_margin = 10
      g.title_font_size = 30
      g.title = q.question.to_s
      g.sort = false
      (0..3).each { |i| g.data( (i+1).to_s , histogram[i]) }
    end
    return g
  end

  

end
