$ ->
    $("#group-selection-form").each ->
        form = $(this)

        school = $("#group-selection-school")
        group = $("#group-selection-group")

        school.autocomplete(
            source: school.data("search-path")
            select: (event, ui) ->
                values = $(this).parents(form).serializeArray()

                # The select event happens before the value is set in the form
                for value, i in values when value.name == "school_name"
                    values[i].value = ui.item.value

                group.prop("disabled", true)

                $.ajax(
                    url: form.data("list-group")
                    data: values
                    success: (data) ->
                        group.html(data).prop("disabled", false)
                    error: ->
                        group.html("<option>Välj skola först</option>")
                    complete: ->
                        form.trigger("school-select")
                )

        )

        group.on "change", ->
            groupId = parseInt(group.find("option:selected").val())
            form.trigger("group-select", [ groupId ])
            $.get(form.data("select-group"), group_id: groupId)

        form.on "click", ".select-group", ->
            groupId = parseInt(group.find("option:selected").val())
            form.trigger("manual-group-select", groupId) if !isNaN(groupId)


    $('#external-event-attendance').each ->
        setup_school_autocomplete = ($school_input) ->
            $row = $school_input.closest('tr')
            $group_select = $row.find('select[name$="[group_id]"]')

            school_query_url = $school_input.data('search-path')
            group_options_url = $group_select.data('list-group')

            $school_input.autocomplete(
                source: school_query_url
                select: (event, ui) ->
                    values = $form.serializeArray()
                    selected_school_name = ui.item.value

                    # The select event happens before the value is set in the form
                    for value, i in values when value.name == 'school_name'
                        values[i].value = ui.item.value

                    $group_select.prop('disabled', true)

                    $.ajax(
                        url: group_options_url
                        data: { school_name: selected_school_name, do_not_update_session: true }
                        success: (data) ->
                            $group_select.html(data).prop('disabled', false)
                        error: ->
                            $group_select.html('<option>Välj skola först</option>')
                        complete: ->
                            #console.log('list-group: complete...')
                    )
            )

        $form = $(this)
        $submit_button = $form.find('input[type=submit]')
        $add_row_button = $form.find('button#add-row')

        $school_inputs = $form.find('input[name$="[school_name]"]')
        $group_selects = $form.find('select[name$="[group_id]"]')

        $add_row_button.on 'click', ->
            $table = $form.find('table')
            $last_row = $form.find('tbody tr:last')
            $new_row = $last_row.clone()
            index = $table.find('tbody tr').length

            $school_input = $new_row.find('input[name$="[school_name]"]')

            $new_row.find('input[name$="[booking_id]"]').val('0')
            $school_input.val('').parent().find('span').remove()
            $new_row.find('select[name$="[group_id]"]').html('<option>Välj skola först</option>').prop('disabled', true)
            $new_row.find('input[name$="[student_count]"]').val('0').prop('disabled', true)
            $new_row.find('input[name$="[adult_count]"]').val('0').prop('disabled', true)
            $new_row.find('input[name$="[wheelchair_count]"]').val('0').prop('disabled', true)
            $table.append($new_row)
            setup_school_autocomplete $school_input

        $school_inputs.each ->
            $school_input = $(this)
            setup_school_autocomplete $school_input

        $form.on 'change', 'select[name$="[group_id]"]', ->
            $group_select = $(this)
            $row = $group_select.closest('tr')
            $inputStudent = $row.find('input[name$="[student_count]"]')
            $inputAdult = $row.find('input[name$="[adult_count]"]')
            $inputWheelchair = $row.find('input[name$="[wheelchair_count]"]')

            group_id = parseInt($group_select.val())
            if !isNaN(group_id)
                $submit_button.prop('disabled', false)
                $inputStudent.prop('disabled', false)
                $inputAdult.prop('disabled', false)
                $inputWheelchair.prop('disabled', false)
                $inputStudent.focus()
            else
                #$submit.prop('disabled', true)
                $inputStudent.prop('disabled', true)
                $inputAdult.prop('disabled', true)
                $inputWheelchair.prop('disabled', true)

    $("#booking-list").each ->
        list = $(this)

        # Handle changes in the group selection
        groupSelection = $("#group-selection-form")

        groupSelection.on "group-select", (event, groupId) ->
            return if isNaN(groupId)

            params = { group_id: groupId }

            $.get list.data("list-path"), params, (data) ->
                list.html(data)

        groupSelection.on "school-select", ->
            list.html("")
