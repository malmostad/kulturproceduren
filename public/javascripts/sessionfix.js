(function($) {
    $(function() {
        if ($("#kp .login-form").length > 0) {
            /**
             * Ajax fix for session problems when going from proxy portlet mode
             * to standalone mode. This method fetches the session id with
             * cookie parameters from the application and sets the cookie
             * client side.
             */
            $.getJSON(kpConfig.sessionfix.url, function(data, status) {
                if (status = "success") {
                    $.cookie(data["name"], data["value"], data["options"])
                }
            });
        }
    });
})(jQuery);
