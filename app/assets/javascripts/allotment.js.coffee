$ ->
    $("#allotment-init-form").each ->
        form = $(this)

        # Automatic date setting for fields depending on the release date
        form.on "change", "#allotment_release_date", ->
            date = new Date($(this).val())

            # Only update fields that have not been changed by the user
            fields = form.find("[data-default-interval]:not(.changed)")

            if isNaN(date.getTime())
                fields.val("")
            else
                fields.each ->
                    input = $(this)
                    interval = parseInt(input.data("default-interval"))

                    newDate = new Date()
                    newDate.setDate(date.getDate() + interval)
                    input.datepicker("setDate", newDate)

        # Handle manual changes of the dependent date fields
        form.on "change", "[data-default-interval]", -> $(this).addClass("changed")

        # Hide districts if the user selects "free_for_all"
        form.on 'change', 'input[name=allotment\\[ticket_state\\]]', ->
          value = parseInt $(this).val()
          if value == 3
            $('.areas-group').hide()
          else
            $('.areas-group').show()

        # Disable school transition date field when skipping school transition
        form.on "change", "#allotment_skip_school_transition", ->
          form.find("#allotment_school_transition_date").prop("disabled", $(this).is(":checked"))

        # Disable district transition date field when skipping district transition
          form.on "change", "#allotment_skip_district_transition", ->
              form.find("#allotment_district_transition_date").prop("disabled", $(this).is(":checked"))

        # Enable bus booking date field when enabling bus booking
        form.on "change", "#allotment_bus_booking", ->
            form.find("#allotment_last_bus_booking_date").prop("disabled", !$(this).is(":checked"))

        # District checkbox list, toggling the "all" choice
        districts = form.find(".districts")
        districts.on "change", ":checkbox", ->
            input = $(this)
            all = input.hasClass("all")
            checked = input.is(":checked")

            if all
                # "all" was changed, change all other checkboxes
                districts.find(":checkbox:not(.all)").prop("checked", checked)
            else
                # Toggle the state of "all" depending on the state of the others
                unchecked = districts.find(":checkbox:not(.all):not(:checked)").length > 0
                districts.find(":checkbox.all").prop("checked", !unchecked)


    $("#allotment-distribution-form").each ->
        form = $(this)

        # Handle addition of extra groups
        $("#group-selection-form").on "manual-group-select", (event, groupId) ->
            form.find("#add_group_group_id").val(groupId)
            form.submit()


        # Tree structure collapsing
        form.on "click", ".collapser", ->
            collapser = $(this)
            row = collapser.closest("tr")
            type = row.data("type")

            collapser.toggleClass("collapsed")

            if collapser.hasClass("collapsed")
                row.nextUntil("[data-type=#{type}]").hide()
            else
                row.nextUntil("[data-type=#{type}]").show()


        ## Ticket amount handling

        # Parsing function for integer values
        parse = (value) ->
            value = parseInt(value)
            value = 0 if isNaN(value)
            return value

        # The available pool of tickets, setter/getter
        pool = (delta = false) ->
            container = $("#ticket-pool")
            value = parse(container.text())
            if delta == false
                return value
            else
                container.text(value - delta)

        # Update the total display for a district/school row
        updateTotal = (row, delta) ->
            return if row.length <= 0
            display = row.find(".tickets")
            existing = parseInt(display.text())
            display.text(existing + delta)

        # Update ticket pool and totals
        form.on "change", ":input.tickets", ->
            field = $(this)
            previous = parse(field.data("value"))
            current = parse(field.val())

            delta = current - previous

            field.data("value", current)
            pool(delta)

            row = field.closest("tr")
            updateTotal(row.prevAll("[data-type=school]:first"), delta)
            updateTotal(row.prevAll("[data-type=district]:first"), delta)

        # Update row state
        form.on "change", ":input.tickets", ->
            field = $(this)
            row = field.closest("tr")

            current = parse(field.val())
            children = parse(row.find(".children").text())

            row.removeClass("full partial")

            if current >= children && current > 0
                row.addClass("full")
            else if current > 0
                row.addClass("partial")

        # Fill/clear buttons
        fill = (row) ->
            field = row.find(":input.tickets")

            current = parse(field.val())
            children = parse(row.find(".children").text())

            delta = if current >= children
                # If the row already is full, increment the value by 1
                1
            else
                # Fill the row to the amount of children
                children - current

            # The amount added is bounded by the ticket pool
            delta = Math.min(delta, pool())

            field.val(current + delta)
            field.trigger("change")

        clear = (row) ->
            field = row.find(":input.tickets")
            field.val(0)
            field.trigger("change")

        form.on "click", ".fill, .clear", (event) ->
            event.preventDefault()

            button = $(this)
            action = if button.hasClass("fill") then fill else clear
            row = button.closest("tr")

            switch row.data("type")
                when "group", "editable-district" then action(row)
                when "school"
                    # Update all group rows that belong to the school
                    row.nextUntil("[data-type=school]", "[data-type=group]").each ->
                        action($(this))
                when "district"
                    # Update all group rows that belong to the district
                    row.nextUntil("[data-type=district]", "[data-type=group]").each ->
                        action($(this))


        # Make the details display scroll along with the page
        win = $(window)
        details = $("#allotment-details")
        detailsOffset = details.offset()

        win.on "scroll", ->
            if win.scrollTop() > detailsOffset.top
                details.css(
                    position: "fixed"
                    top: "3em"
                    left: "#{detailsOffset.left}px"
                )
            else
                details.css(
                    position: "static"
                )
                detailsOffset = details.offset()
