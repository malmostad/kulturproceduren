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

    $(function () {
        if ($("#kp-group-selection-form").length > 0) {
            /**
             * Fetches schools by Ajax when choosing a district in the group selection fragment
             */
            $("#kp-group_selection-district_id").change(function() {
                var districtId = $("#kp-group_selection-district_id option:selected").val();
                var values = $(this).parents("form").serialize();

                $("#kp-group_selection-district_id").parent().append('<div class="load-indicator"></div>');

                $("#kp-group_selection-school_id").attr("disabled", "disabled");
                $("#kp-group_selection-group_id").html("<option>Välj skola först</option>").attr("disabled", "disabled");

                var request = $.ajax({
                    url: kpConfig.schools.list.url,
                    data: values,
                    success: function(data) {
                        $("#kp-group_selection-school_id").html(data).removeAttr("disabled");
                    },
                    error: function() {
                        $("#kp-group_selection-school_id").html("<option>Välj stadsdel först</option>");
                    },
                    complete: function() {
                        $("#kp-group-selection-form").trigger("districtSelected", [ districtId ]);
                        $("#kp-group_selection-district_id").parent().find('.load-indicator').remove();
                    }
                });

            });
            /**
             * Fetches groups by Ajax when choosing a school in the group selection fragment
             */
            $("#kp-group_selection-school_id").change(function() {
                var schoolId = $("#kp-group_selection-school_id option:selected").val();
                var values = $(this).parents("form").serialize();

                $("#kp-group_selection-school_id").parent().append('<div class="load-indicator"></div>');
                $("#kp-group_selection-group_id").attr("disabled", "disabled");

                var request = $.ajax({
                    url: kpConfig.groups.list.url,
                    data: values,
                    success: function(data, textStatus) {
                        $("#kp-group_selection-group_id").html(data).removeAttr("disabled");
                    },
                    error: function() {
                        $("#kp-group_selection-group_id").html("<option>Välj skola först</option>");
                    },
                    complete: function() {
                        $("#kp-group_selection-school_id").parent().find('.load-indicator').remove();
                        $("#kp-group-selection-form").trigger("schoolSelected", [ schoolId ]);
                    }
                });
            });
            /**
             * Triggers the event groupSelected on the group selection fragment when selecting
             * a group.
             */
            $("#kp-group_selection-group_id").change(function() {
                var groupId = parseInt($("#kp-group_selection-group_id option:selected").val());
                $("#kp-group-selection-form").trigger("groupSelected", [ groupId ])
                $.get(kpConfig.groups.select.url, { group_id: groupId });
            });
        }
    });

    $(function() {
        /**
         * Listeners for group selection fragment events for the notification request form
         */
        $("#kp .notification-request-group-selection #kp-group-selection-form"
        ).bind("groupSelected", function(e, groupId) {
            if (!isNaN(groupId)) {
                // Set the groupId in the form
                $("#kp-notification_request-group_id").val(groupId);
                $("#kp .notification-request-form input").removeAttr("disabled");
            } else {
                // Disable the form
                $("#kp .notification-request-form input").attr("disabled", "disabled");
            }
        }).bind("districtSelected schoolSelected", function(e, id){
            // Disable the form
            $("#kp .notification-request-form input").attr("disabled", "disabled");
        });
        
        /**
         * Listeners for group selection fragment events for the group bookings listing
         */
        $("#kp .group-bookings-group-selection #kp-group-selection-form"
        ).bind("groupSelected", function(e, groupId) {
            if (!isNaN(groupId)) {
                // Load the group booking list
                var request = $.get(kpConfig.booking.groupList.url,
                { group_id: groupId },
                function(data) {
                    var cnt = $("#kp-group-bookings-container");
                    cnt.html(data);

                    // Fix for incoming URL:s in Sitevision
                    var urlBase = $("#kp-sitevision-base-url").attr("href");
                    cnt.find("a").each(function(i, elem) {
                        var link = $(elem);
                        var href = link.attr("href");

                        // Remove the domain name (IE fix)
                        if (href.indexOf("http://") == 0) {
                            href = href.slice(href.indexOf("/", 7));
                        }

                        link.attr("href", urlBase.substr(0, urlBase.length - 1) + href);
                    });
                });
            } else {
                $("#kp-group-bookings-container").html("");
            }
        }).bind("districtSelected schoolSelected", function(e, id){
            $("#kp-group-bookings-container").html("");
        });
    });

    $(function() {
        /**
         * Shows the multiple choice input field when choosing the question type
         * "multiple choice".
         */
        $("#kp .question-form .types-field-row :radio").click(function() {
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
         * TODO: handle non-number input
         */
        var changeHandler = function() {
            var inputs = $("#kp #kp-booking-form-container .num-seats");
            var i;
            var sum = 0;

            for ( i = 0 ; i < inputs.length ; i++) {
                if (!isNaN(Number(inputs[i].value))) {
                    sum += Number(inputs[i].value);
                }
            };

            $("#kp-booking-count").html("<span>Du har angett totalt " + String(sum) + " platser.</span>");
        };

        $("#kp-booking-form-container").change(changeHandler);
        $("#kp-booking-form-container").keyup(changeHandler);

        $("<p id=\"kp-booking-count\" class=\"booking-count message response\"></p>").appendTo(
        "#kp-booking-form-container .seats-container");
        changeHandler();

        /**
         * Listeners for group selection fragment events for the booking form
         */
        $("#kp .booking-group-selection #kp-group-selection-form"
        ).bind("groupSelected", function(e, groupId) {
            if (!isNaN(groupId)) {
                var occasionId = $("#kp-occasion_id").val();

                $("#kp-group_selection-group_id").parent().append('<div class="load-indicator"></div>');

                var request = $.get(
                kpConfig.booking.form.url,
                { group_id: groupId, occasion_id: occasionId },
                function(data) {
                    $("#kp-booking-form-container").html(data);
                    $("#kp-group_selection-group_id").parent().find('.load-indicator').remove();

                    // Hack the incoming URL for use in Sitevision
                    var base = $("#kp-sitevision-base-url").attr("href");
                    var form = $("#kp-booking-form-container form.booking-form");
                    var path = form.attr("action");
                    // Strip the trailing slash from the base
                    form.attr("action", base.substr(0, base.length - 1) + path);

                    $("<p id=\"kp-booking-count\" class=\"booking-count message response\"></p>").appendTo(
                    "#kp-booking-form-container .seats-container");
                    changeHandler();
                });

            } else {
                // Disable the form
                $("#kp-booking-form-container").html("");
            }
        }).bind("districtSelected schoolSelected", function(e, id){
            // Disable the form
            $("#kp-booking-form-container").html("");
        });

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
            minDate: tomorrow,
            onSelect: function(dateText, inst) {
                var date = new Date(dateText);
                $("#kp #kp-allotment-district_transition_date:not(.changed),\
                    #kp #kp-allotment-free_for_all_transition_date:not(.changed)").each(function() {
                    var $field = $(this),
                        defaultInterval = parseInt($field.attr("data-default-interval")),
                        newDate = new Date();
                    newDate.setDate(date.getDate() + defaultInterval);
                    $field.val($.datepicker.formatDate("yy-mm-dd", newDate));
                });
            }
        });
        $("#kp #kp-allotment-district_transition_date,\
            #kp #kp-allotment-free_for_all_transition_date").datepicker({
            minDate: tomorrow,
            onSelect: function() {
                $(this).addClass("changed");
            }
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

    $(function() {
        /**
         * Hijacks the link going to the list with ticket availability
         * and displays the list using Ajax in a UI dialog.
         */
        $("#kp .calendar-list .ticket-availability-link").click(function() {
            var link = $(this);
            var url = link.attr("href");
            var linkContainer = link.parent();

            link.hide();
            linkContainer.append('<div class="load-indicator"></div>');

            $.get(url, function(data) {

                linkContainer.find(".load-indicator").remove();
                link.show();

                dialogContainer = $("#kp-ticket-availability-dialog");

                if (dialogContainer.length > 0) {
                    dialogContainer.children().remove();
                    dialogContainer.dialog("destroy");
                } else {
                    dialogContainer = $("<div id=\"kp-ticket-availability-dialog\"></div>").appendTo("body");
                }

                var d = $(data);
                dialogContainer.append(d);

                // Fix for incoming URL:s in Sitevision
                var urlBase = $("#kp-sitevision-base-url").attr("href");
                dialogContainer.find("a").each(function(i, elem) {
                    var link = $(elem);
                    var href = link.attr("href");

                    // Remove the domain name (IE fix)
                    if (href.indexOf("http://") == 0) {
                        href = href.slice(href.indexOf("/", 7));
                    }

                    link.attr("href", urlBase.substr(0, urlBase.length - 1) + href);
                });

                dialogContainer.dialog({
                    width: 640,
                    height: 480,
                    modal: true,
                    resizable: false,
                    draggable: true,
                    title: link.attr("title"),
                    close: function() { dialogContainer.dialog("destroy").remove(); }
                });
            });

            return false;
        });
    });

    $(function() {
        /**
         * Hides the age inputs when selecting further education in the event
         * form.
         */
        $("#kp #kp-event-further_education").click(function() {
            if ($(this).is(":checked")) {
                $("#kp .from_age-field-row, #kp .to_age-field-row").hide();
            } else {
                $("#kp .from_age-field-row, #kp .to_age-field-row").show();
            }
        });
    });

    $(function() {
        /**
         * Ajax functionality for selecting an event when adding links
         * between events.
         */
        $("#kp #kp-event_link-culture_provider_id").change(function() {
            var cpId = parseInt($(this).val());

            if (!isNaN(cpId) && cpId > 0) {
                $.get(
                kpConfig.events.list.url,
                { "culture_provider_id": cpId },
                function(data) {
                    $("#kp-event_link-event_id").html(data).removeAttr("disabled", "disabled");
                    $("#kp-event_link-submit").removeAttr("disabled", "disabled");
                });
            } else {
                $("#kp-event_link-event_id, #kp-event_link-submit").attr("disabled", "disabled");
            }
        });
    });

})(jQuery);
