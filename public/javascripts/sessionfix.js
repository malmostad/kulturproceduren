(function($) {
    $(function() {
        $.getJSON(kpConfig.sessionfix.url, function(data, status) {
            if (status = "success") {
                $.cookie(data["name"], data["value"], data["options"])
            }
        });
    });
})(jQuery);
