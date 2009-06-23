(function($) {
    $(function() {

        // Checkbox lists
        $(".checkbox-list :checkbox").change(function() {
            var cb = $(this);
            var l = cb.parents(".checkbox-list");

            if (cb.hasClass("all-toggler")) {
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
        $("#kp-district_id").change(function() {
            var district_id = $("#kp-district_id option:selected").val();
            var request = $.get(
                kpConfig.schools.list.url,
                {
                    district_id: district_id
                },
                function(data) {
                    $("#kp-school_id").html(data);
                }
                );
            $("#kp-group_id").html("<option>Välj skola först</option>");
        });
        $("#kp-school_id").change(function() {
            var schoolId = $("#kp-school_id option:selected").val();
            var occasionId = $("#kp-occasion_id").val();
            var request = $.get(
                kpConfig.groups.list.url,
                {
                    school_id: schoolId ,
                    occasion_id : occasionId
                }, function(data) {
                    $("#kp-group_id").html(data);
                });
        });
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
        $(".kp-rbclass").click(function() {
            if ( this.id == "kp-qtype_questionmchoice")
                $("#kp-query-mchoice-csv").show("slow");
            else
                $("#kp-query-mchoice-csv").hide("slow");
       
        });
       
    });

    $(document).ready(function(){
        if ($("#kp-qtype_questionmchoice").attr("checked"))
            $("#kp-query-mchoice-csv").show();
        else
            $("#kp-query-mchoice-csv").hide();
    });

    //Drop-down
    $(function() {
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

    // Date selectors
    $(function() {
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

        var today = new Date();
        $("#kp .date-field.auto").datepicker({
            minDate: new Date()
        });

        var tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        
        $("#kp #kp-allotment-release_date").datepicker({
            minDate: tomorrow
        });

        $("#kp #kp-calendar-filter-from-date, #kp #kp-calendar-filter-to-date").datepicker();
    });

    $(function() {
        $("#kp .tabs").tabs();

        $("#kp .tabs .preselect").each(function () {
            var tab = $(this);
            var tabIdx = tab.parent().children("li").index(tab);
            tab.parents(".ui-tabs").tabs("select", tabIdx);
        });
    });

    $(function() {
        $("#kp .model-cnt .images-cnt .images").cycle("fade");

        $("#kp fieldset.collapsible legend").click(function() {
            $(this).parent().toggleClass("collapsed");
        });
    });

    $(function() {
        $("#kp .show-calendar-filter-action").click(function () {
            $(this).hide();
            $("#kp .calendar-filter").show();
            $("#kp #kp-calendar-filter-show").val(1);
            return false;
        });
        $("#kp .calendar-filter .hide-calendar-filter-action").click(function () {
            $("#kp .calendar-filter").hide();
            $("#kp .show-calendar-filter-action").show();
            $("#kp #kp-calendar-filter-show").val(0);
            return false;
        });

        $("#kp #kp-calendar-filter-further-education-true").change(function() {
            if ($(this).is(":checked")) {
                $("#kp #kp-calendar-filter-from-age, #kp #kp-calendar-filter-to-age").attr("disabled", "disabled");
            }
        });
        $("#kp #kp-calendar-filter-further-education-false").change(function() {
            if ($(this).is(":checked")) {
                $("#kp #kp-calendar-filter-from-age, #kp #kp-calendar-filter-to-age").removeAttr("disabled");
            }
        });
    });
   
})(jQuery);