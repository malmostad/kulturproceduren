$ ->
    $("#role-application-form").each ->
        form = $(this)

        roleSelector = form.find(".role_application_role_id")

        roleSelector.on "change", ":radio", ->
            # Hide everything that's dependent on which role is selected
            form.find(".role-dependent").hide()
            form.find(".role-dependent :input").prop("disabled", true)

            # Show the fields dependent on the currently selected role
            roleId = $(this).val()
            form.find(".role-dependent[data-role-id=#{roleId}]").show()
            form.find(".role-dependent[data-role-id=#{roleId}] :input").prop("disabled", false)

        # Initialize the form
        roleSelector.find(":checked").trigger("change")

    $("#booking-form").each ->
        form = $(this)

        form.on "change keyup", ":input.seats", ->
            # Sum the total amount of seats
            total = 0
            form.find(":input.seats").each ->
                v = Number(this.value)
                total += v if !isNaN(v)

            form.find(".total-seats").html("Du har angett totalt <b>#{total}</b> platser.")

        # Prepopulate the total seats display
        form.find(":input.seats:first").trigger("change")


        # Handle changes in the group selection
        groupSelection = $("#group-selection-form")

        groupSelection.on "group-select", (event, groupId) ->
            return if isNaN(groupId)

            params = {
                group_id: groupId,
                occasion_id: form.data("occasion-id")
            }

            $.get form.data("form-path"), params, (data) ->
                form.html(data)
                form.find(":input.seats:first").trigger("change")

        groupSelection.on "school-select", ->
            form.html("")

