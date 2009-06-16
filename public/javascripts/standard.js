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
        $("#kp .date-input-field").datepicker({ 
            dateFormat: "yy-mm-dd",
            minDate: new Date(),
            firstDay: 1,
            dayNames: ['söndag', 'måndag', 'tisdag', 'onsdag', 'torsdag', 'fredag', 'lördag'],
            dayNamesMin: ['sö', 'må', 'ti', 'on', 'to', 'fr', 'lö'],
            dayNamesShort: ['sön', 'mån', 'tis', 'ons', 'tor', 'fre', 'lör'],
            monthNames: ['januari', 'februari', 'mars', 'april', 'maj', 'juni', 'juli', 'augusti', 'september', 'oktober', 'november', 'december'],
            monthNamesShort: ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec']
        });
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
   
})(jQuery);