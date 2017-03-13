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
        $form = $(this)

        $school_input = $form.find('input[name=school_name]')
        $group_select = $form.find('select[name=group_id]')
        $submit = $form.find('input[type=submit]')
        $inputStudent = $form.find('input[name=student]')
        $inputAdult = $form.find('input[name=adult]')
        $inputWheelchair = $form.find('input[name=wheelchair]')

        school_query_url = $school_input.data('search-path')
        group_options_url = $group_select.data('list-group')

        $school_input.autocomplete(
            source: school_query_url
            select: (event, ui) ->
                values = $form.serializeArray()

                # The select event happens before the value is set in the form
                for value, i in values when value.name == 'school_name'
                    values[i].value = ui.item.value

                $group_select.prop('disabled', true)

                $.ajax(
                    url: group_options_url
                    data: values
                    success: (data) ->
                        $group_select.html(data).prop('disabled', false)
                    error: ->
                        $group_select.html('<option>Välj skola först</option>')
                    complete: ->
                        #console.log('list-group: complete...')
                )
        )

        $group_select.on 'change', ->
            group_id = parseInt($group_select.val())
            if !isNaN(group_id)
                $submit.prop('disabled', false)
                $inputStudent.prop('disabled', false)
                $inputAdult.prop('disabled', false)
                $inputWheelchair.prop('disabled', false)
                $inputStudent.focus()
            else
                $submit.prop('disabled', true)
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
