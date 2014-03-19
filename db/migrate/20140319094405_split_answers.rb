#
# Previously, an answer to multiple choice question have been YAML serialized into the answer_text
# field in a single answer row. ({answer_text => 1})
#
# This migration splits such answers into multiple answer rows, and also removes the YAML serialization.
#
# However, one of the questions (id 123) has had its type changed after users had starting to submit answers.
# Hence some answer rows are skipped since they already have the correct format (for some value of 'correct').
#
# The old values in the answers table are backed up for easier rollback, and can be deleted in the future.
#
class SplitAnswers < ActiveRecord::Migration

  @@skipped = []

  def up
    execute "SELECT * INTO TABLE backup_merged_answers FROM answers"
    puts "Before: #{Answer.count}"
  	Answer.joins(:question).where("questions.qtype = ?", "QuestionMchoice").each{ |a| split_answer(a) }
    puts "After: #{Answer.count}"
    puts "Skipped answers: #{@@skipped.length}"
    puts "Skipped question ids: #{@@skipped.map(&:question_id).uniq}"
  end


  def down
    execute <<-SQL
      TRUNCATE TABLE answers;
      INSERT INTO answers (SELECT * FROM backup_merged_answers);
      DROP TABLE backup_merged_answers;
    SQL
  end


  def split_answer(answer)
    deserialized = YAML.load(answer.answer_text)
    
    if deserialized.kind_of? Hash
      deserialized.keys.each{ |answer_text| copy_answer(answer, answer_text) }
      answer.destroy
    else
      @@skipped << answer
    end
  end

  def copy_answer(original, text)
    Answer.create! do |a|
      a.answer_form_id = original.answer_form_id
      a.question_id    = original.question_id
      a.answer_text    = text
      a.created_at     = original.created_at
      a.updated_at     = original.updated_at
    end
  end
end
