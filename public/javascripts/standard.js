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
        $("#kp-district_id").change(function() {
           var district_id = $("#kp-district_id option:selected").val();
           var request = $.get(
                              "/booking/get_schools",
                              { district_id: district_id },
                              function(data) {
                                  $("#kp-school_id").html(data);
                              }
                            );
          $("#kp-group_id").html("<option>Välj skola först</option>");
        });
        $("#kp-school_id").change(function() {
           var school_id = $("#kp-school_id option:selected").val();
           var occasion_id = $("#kp-occasion_id").val();
           var request = $.get("/booking/get_groups", { school_id: school_id , occasion_id : occasion_id}, function(data) {$("#kp-group_id").html(data);});
        });
        $("#kp-group_id").change(function() {
           var group_id = $("#kp-group_id option:selected").val();
           var occasion_id = $("#kp-occasion_id").val();
           var request = $.get(
                              "/booking/get_input_area", 
                              {group_id: group_id , occasion_id : occasion_id } ,
                              function(data) {
                                  $("#kp-input-area").html(data);
                              }
                            );
                            
        });
        
       
     });
    //Drop-down
   $(document).ready(function() {
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

   
})(jQuery);