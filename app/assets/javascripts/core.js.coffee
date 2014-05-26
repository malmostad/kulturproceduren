$ ->
    $("input.datepicker").each ->
        input = $(this)
        input.datepicker(
            language: "sv"
            format: "yyyy-mm-dd"
            weekStart: 1
            autoclose: true
            todayHighlight: true
            startDate: input.data("start-date")
        )
