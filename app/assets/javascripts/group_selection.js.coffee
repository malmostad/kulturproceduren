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
