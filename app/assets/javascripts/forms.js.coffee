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
