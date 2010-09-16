(function($) {
    $(function() {
        /**
         * Injects a link for triggering a test preview of a map address.
         */
        $("#kp form .map_address-field-row .input-container").append(
        '<a class="map-address-test-trigger" href="#">Testa adressen</a>'
        );

        /**
         * Listener for the map test preview.
         */
        $("#kp .map-address-test-trigger").live("click", function () {
            var address = $(this).siblings(":text").val();

            if (address.length > 0) {
                $.malmo.map.showSingleLocation(address);
            }

            return false;
        });

        /**
         * Listener for the map test preview.
         */
        $("#kp .map-address-link").live("click", function () {
            $.malmo.map.showSingleLocation($(this).attr("title"));
            return false;
        });
    });
})(jQuery);
