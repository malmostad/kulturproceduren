(function($) {
    $(function() {
        /**
         * Ajax-fix för sessionsproblem när man går från proxyportletläge
         * till fristående läge. Hämtar sessions-id med tillhörande cookie-parametrar
         * från applikationen och sätter cookien på klientsidan.
         */
        $.getJSON(kpConfig.sessionfix.url, function(data, status) {
            if (status = "success") {
                $.cookie(data["name"], data["value"], data["options"])
            }
        });
    });
})(jQuery);
