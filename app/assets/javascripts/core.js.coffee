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


    $("#slideshow").each ->
        slideshow = $(this)
        images = slideshow.find(".images")
        imgs = images.children("img")

        imgs.show()

        return if imgs.length <= 1

        slideshow.find("menu").show()

        images.cycle(
            fx: "fade"
            speed: 200
            autoHeight: "calc"
            swipe: true
            next: "#slideshow menu .next, #slideshow img"
            prev: "#slideshow menu .prev"
        )
