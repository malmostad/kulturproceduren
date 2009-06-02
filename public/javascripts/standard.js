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
        $("#district_id").change(function() { 
           var district_id = $("#district_id option:selected").val();
           var request = $.get(
                              "/booking/get_schools",
                              { district_id: district_id },
                              function(data) {
                                  $("#school_id").html(data);
                              }
                            );
          $("#group_id").html("<option>Välj skola först</option>");
        });
        $("#school_id").change(function() {
           var school_id = $("#school_id option:selected").val();
           var occasion_id = $("#occasion_id").val();
           var request = $.get("/booking/get_groups", { school_id: school_id , occasion_id : occasion_id}, function(data) {$("#group_id").html(data);});
        });
        $("#group_id").change(function() {
           var request = $.get(
                              "/booking/get_input_area", {} , function(data) {
                                  $("#input-area").html(data);
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
           $("#booking-count").html("Du har totalt bokat <blink>" + String(sum) + "</blink> biljetter.");
       };
       $("#input-area").change(changeHandler);
       $("#input-area").keypress(changeHandler);
   });

   
})(jQuery);