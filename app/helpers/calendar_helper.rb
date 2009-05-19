module CalendarHelper
  def month_name(m)
    name = case m
    when 1 then "Januari"
    when 2 then "Februari"
    when 3 then "Mars"
    when 4 then "April"
    when 5 then "Maj"
    when 6 then "Juni"
    when 7 then "Juli"
    when 8 then "Augusti"
    when 9 then "September"
    when 10 then "Oktober"
    when 11 then "November"
    when 12 then "December"
    end
    return name
  end

end
