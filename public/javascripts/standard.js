(function($) {
    $(function() {
        /**
         * Change trigger for checkboxes in a checkbox list.
         * 
         * Handles "select all" functionality as well as the value of
         * the "select all" checkbox when other checkboxes are changed.
         */
        $(".checkbox-list :checkbox").change(function() {
            var cb = $(this);
            var l = cb.parents(".checkbox-list");

            if (cb.hasClass("all-toggler")) {
                // "Select all"
                if (cb.is(":checked")) {
                    l.find(":checkbox:not(:checked)").attr("checked", true);
                } else {
                    l.find(":checkbox:checked").attr("checked", false);
                }
            } else {
                if (cb.is(":checked")) {
                    if (l.find(":checkbox:not(:checked):not(.all-toggler)").length <= 0) {
                        l.find(".all-toggler").attr("checked", true);
                    }
                } else {
                    l.find(".all-toggler").attr("checked", false);
                }
            }
        });
    });

    $(function() {
        /**
         * Fetches schools by Ajax when choosing a district in the booking view.
         */
        $("#kp-district_id").change(function() {
            var district_id = $("#kp-district_id option:selected").val();
            var occasion_id = $("#kp-occasion_id").val();
            var request = $.get(
                kpConfig.schools.list.url,
                {
                    district_id: district_id ,
                    occasion_id: occasion_id
                },
                function(data) {
                    $("#kp-school_id").html(data);
                }
                );
            $("#kp-group_id").html("<option>Välj skola först</option>");
        });
        /**
         * Fetches groups by Ajax when choosing a school in the booking view.
         */
        $("#kp-school_id").change(function() {
            var schoolId = $("#kp-school_id option:selected").val();
            var occasion_id = $("#kp-occasion_id").val();
            var request = $.get(
                kpConfig.groups.list.url,
                {
                    school_id: schoolId ,
                    occasion_id: occasion_id
                }, function(data) {
                    $("#kp-group_id").html(data);
                });
        });
        /**
         * Fetches the form by Ajax when choosing a group in the booking view.
         */
        $("#kp-group_id").change(function() {
            var groupId = $("#kp-group_id option:selected").val();
            var occasionId = $("#kp-occasion_id").val();
            var request = $.get(
                kpConfig.booking.bookingInput.url,
                {
                    group_id: groupId ,
                    occasion_id : occasionId
                },
                function(data) {
                    $("#kp-input-area").html(data);
                });
        });


        /**
         * Fetches schools by Ajax when choosing a district in the notification request view.
         */
        $("#kp-notreq-district_id").change(function() {
            var district_id = $("#kp-notreq-district_id option:selected").val();
            var request = $.get(
                kpConfig.schools.list.url,
                {
                    district_id: district_id ,
                },
                function(data) {
                    $("#kp-notreq-shool_id").html(data);
                }
                );
            $("#kp-notification_request-group_id").html("<option>Välj skola först</option>");
        });
        /**
         * Fetches groups by Ajax when choosing a school in the notification request view.
         */
        $("#kp-notreq-shool_id").change(function() {
            var schoolId = $("#kp-notreq-shool_id option:selected").val();
            var request = $.get(
                kpConfig.groups.list.url,
                {
                    school_id: schoolId ,
                }, function(data) {
                    $("#kp-notification_request-group_id").html(data);
                });
        });
        /**
         * Fetches the form by Ajax when choosing a group in the notification request view.
         */
        $("#kp-notification_request-group_id").change(function() {
            var groupId = $("#kp-notification_request-group_id option:selected").val();
            var occasionId = $("#kp-occasion_id").val();
            var userId = $("#kp-user_id").val();
            var request = $.get(
                kpConfig.notreq.notreqInput.url,
                {
                    group_id: groupId ,
                    occasion_id : occasionId ,
                    user_id : userId
                },
                function(data) {
                    $("#kp-notreq-input-area").html(data);
                });
        });


        /**
         * Fetches schools by Ajax when choosing a district in the booking list view.
         */
        $("#kp-by_group_district_id").change(function() {
            var district_id = $("#kp-by_group_district_id option:selected").val();
            var request = $.get(
                kpConfig.schools.list.url,
                {
                    district_id: district_id
                },
                function(data) {
                    $("#kp-by_group_school_id").html(data);
                }
                );
            var request2 = $.get(
                kpConfig.by_group.byGroupList.url,
                { },
                function(data) {
                    $("#kp-booking-by-group").html(data);
                });
            $("#kp-by_group_group_id").html("<option>Välj skola först</option>");
        });
        /**
         * Fetches groups by Ajax when choosing a school in the booking list view.
         */
        $("#kp-by_group_school_id").change(function() {
            var schoolId = $("#kp-by_group_school_id option:selected").val();
            var request = $.get(
                kpConfig.groups.list.url,
                {
                    school_id: schoolId
                }, function(data) {
                    $("#kp-by_group_group_id").html(data);
                });
            var request2 = $.get(
                kpConfig.by_group.byGroupList.url,
                { },
                function(data) {
                    $("#kp-booking-by-group").html(data);
                });

        });
        /**
         * Fetches the booking list by Ajax when choosing a group in the booking list view.
         */
        $("#kp-by_group_group_id").change(function() {
            var groupId = $("#kp-by_group_group_id option:selected").val();
            var request = $.get(
                kpConfig.by_group.byGroupList.url,
                {
                    group_id: groupId
                },
                function(data) {
                    $("#kp-booking-by-group").html(data);
                });
        });
    });

    $(function() {
        /**
         * Shows the multiple choice input field when choosing the question type
         * "multiple choice".
         */
        $("#kp .question-form .types-field-row :radio").change(function() {
            if ($(this).val() == "QuestionMchoice") {
                $("#kp .question-form .choice_csv-field-row").show("slow");
            } else {
                $("#kp .question-form .choice_csv-field-row").hide("slow")
            }
        });
    });

    $(function() {
        /**
         * Sums the number of booked tickets in the booking view.
         */
        var changeHandler = function() {
            var inputs = $(".seats");
            var i;
            var sum = 0;

            for ( i = 0 ; i < inputs.length ; i++) {
                sum += Number(inputs[i].value);
            };

            $("#kp-booking-count").html("<span class=\"booking-no-tickets\">Du har totalt bokat " + String(sum) + " biljetter.</span>");
        };

        $("#kp-input-area").change(changeHandler);
        $("#kp-input-area").keyup(changeHandler);
    });

    $(function() {
        /**
         * Default settings for the date picker.
         */
        $.datepicker.setDefaults({
            dateFormat: "yy-mm-dd",
            firstDay: 1,
            showOn: "both",
            buttonText: "Visa kalender",
            dayNames: ['söndag', 'måndag', 'tisdag', 'onsdag', 'torsdag', 'fredag', 'lördag'],
            dayNamesMin: ['sö', 'må', 'ti', 'on', 'to', 'fr', 'lö'],
            dayNamesShort: ['sön', 'mån', 'tis', 'ons', 'tor', 'fre', 'lör'],
            monthNames: ['januari', 'februari', 'mars', 'april', 'maj', 'juni', 'juli', 'augusti', 'september', 'oktober', 'november', 'december'],
            monthNamesShort: ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec']
        });

        // The minimum date is today on an auto date field
        var today = new Date();
        $("#kp .date-field.auto").datepicker({
            minDate: new Date()
        });

        // The minimum date is tomorrow on the ticket release date field
        var tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        
        $("#kp #kp-allotment-release_date").datepicker({
            minDate: tomorrow
        });

        // Default settings on the date fields in the filter form
        $("#kp #kp-calendar-filter-from-date, #kp #kp-calendar-filter-to-date").datepicker();
    });

    $(function() {
        // Tabs
        $("#kp .tabs").tabs();

        /**
         * Preselection of tabs.
         */
        $("#kp .tabs .preselect").each(function () {
            var tab = $(this);
            var tabIdx = tab.parent().children("li").index(tab);
            tab.parents(".ui-tabs").tabs("select", tabIdx);
        });
    });

    $(function() {
        /**
         * Image cycling
         */
        $("#kp .model-cnt .images-cnt").each(function() {
            var c = $(this);
            var imgs = c.find("img");

            if (imgs.length > 1) {
                    
                c.find(".images").cycle("fade");

                // Trigger for playing/pausing the cycling.
                $("<a href=\"#\" class=\"play-pause-action playing\">Spela/Pausa</a>").appendTo(c).toggle(
                    function() {
                        $(this).removeClass("playing").addClass("paused").siblings(".images").cycle("pause");
                    },
                    function() {
                        $(this).removeClass("paused").addClass("playing").siblings(".images").cycle("resume", true);
                    });
            }
        });
    });

    $(function() {
        /**
         * Collapsible fieldsets
         */
        $("#kp fieldset.collapsible legend").click(function() {
            $(this).parent().toggleClass("collapsed");
        });
    });

    $(function() {
        /**
         * Disable age filters when choosing further education
         */
        $("#kp #kp-calendar-filter-further-education-true").change(function() {
            if ($(this).is(":checked")) {
                $("#kp #kp-calendar-filter-from-age, #kp #kp-calendar-filter-to-age").attr("disabled", "disabled");
            }
        });
        /**
         * Enable age filters when discarding further education
         */
        $("#kp #kp-calendar-filter-further-education-false").change(function() {
            if ($(this).is(":checked")) {
                $("#kp #kp-calendar-filter-from-age, #kp #kp-calendar-filter-to-age").removeAttr("disabled");
            }
        });
    });
   
})(jQuery);
