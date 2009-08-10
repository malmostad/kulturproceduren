(function($) {
    $(function() {

        // Datastruktur för fördelningens tillstånd
        var tickets = {
            // Totalt antal tillgängliga biljetter
            total: parseInt($("#kp #kp-distribution-meta .available-tickets").html()),
            // Funktion för att hämta num st tillgängliga biljetter
            getAvailable: function(num) {
                var added = 0;

                if (num <= this.total) {
                    this.total -= num;
                    added = num;
                } else {
                    added = this.total;
                    this.total = 0;
                }
                this.updateDisplay();
                return added;
            },
            // Funktion för att uppdatera antalet tillgängliga biljetter
            change: function(num) {
                this.total += num;
                this.updateDisplay();
            },
            // Uppdaterar gränssnittet med antalet tillgängliga biljetter
            updateDisplay: function() {
                $("#kp #kp-distribution-meta .available-tickets").html(this.total);
            }
        };

        /**
         * Uppdaterar antalet tilldelade biljetter på en stadsdelsrad.
         *
         * @param districtId Stadsdelens id
         */
        function updateDistrictDisplay(districtId) {
            var sum = 0;

            // Summera alla grupprader som är barn till stadsdelsraden
            $("." + districtId + " .num-tickets-value").each(function() {
                sum += parseInt($(this).val());
            });

            $("#" + districtId + " .num-tickets").html(sum);
        }

        /**
         * Uppdaterar antalet tilldelade biljetter på en skolrad.
         *
         * @param schoolId Skolans id
         */
        function updateSchoolDisplay(schoolId) {
            var sum = 0;

            // Summera alla grupprader som är barn till skolan
            $("." + schoolId + " .num-tickets-value").each(function() {
                sum += parseInt($(this).val());
            });

            $("#" + schoolId + " .num-tickets").html(sum);
        }

        /**
         * Hämtar antalet barn och antalet fördelade biljetter på en given rad
         *
         * @param row Raden data ska hämtas ifrån
         */
        function getRowData(row) {
            var data = {
                row: row
            };

            data.childCnt = row.find(".num-children");
            data.numChildren = parseInt(data.childCnt.html());

            data.ticketCnt = row.find(".num-tickets-value");
            data.numTickets = parseInt(data.ticketCnt.val());

            return data;
        }

        /**
         * Trigger för när antalet biljetter förändras på en rad via hidden-fältet.
         */
        $("#kp #kp-distribution-list .num-tickets-value").change(function() {
            var field = $(this);
            var row = field.parents("tr");
            var rowData = getRowData(row);

            // Uppdatera fyll-indikatorn
            row.removeClass("partial full error overbooked");

            if (rowData.numTickets == NaN || rowData.numTickets < 0) {
                row.addClass("error");
            } else if (rowData.numTickets > 0 && rowData.numTickets < rowData.numChildren) {
                row.addClass("partial");
            } else if (rowData.numTickets == rowData.numChildren) {
                row.addClass("full");
            } else if (rowData.numTickets > rowData.numChildren) {
                row.addClass("overbooked");
            }

            // Uppdatera textfältet
            field.siblings(".num-tickets-display").val(field.val());

            // Uppdatera föräldrar
            if (field.hasClass("group-row")) {
                try {
                    updateSchoolDisplay(row.attr("className").match(/kp-school-\d+/)[0]);
                } catch (e) {}
                try {
                    updateDistrictDisplay(row.attr("className").match(/kp-district-\d+/)[0]);
                } catch(e) {}
            }
        });

        /**
         * Trigger för när antalet biljetter förändras på en rad via textfältet.
         */
        $("#kp #kp-distribution-list .num-tickets-display").change(function() {
            var field = $(this);
            var newVal = parseInt($(this).val());
            var rowData = getRowData(field.parents("tr"));

            // Uppdatera totala värdet
            tickets.change(rowData.numTickets - newVal);
            rowData.ticketCnt.val(newVal).trigger("change");
        });


        /**
         * Gemensam funktion för att via tool-knappar fylla/tömma en rads fördelning.
         *
         * @param link Tool-knappen som klickades
         * @param fill Indikator för huruvida raden ska fyllas eller tömmas
         */
        function changeAmount(link, fill) {
            var rowData = getRowData($(link).parents("tr"));

            var tc = 0;

            if (fill) {
                if (rowData.numTickets >= rowData.numChildren) {
                    return;
                }

                tc = tickets.getAvailable(rowData.numChildren - rowData.numTickets) + rowData.numTickets;
            } else {
                tickets.change(rowData.numTickets);
            }

            rowData.ticketCnt.val(tc).trigger("change");
        }

        /**
         * Trigger för tool-knappen "fyll" på en grupprad eller en stadsdelsrad beroende
         * på vilken nivå fördelningen görs.
         */
        $("#kp #kp-distribution-list .group-row .tools .fill, #kp #kp-distribution-list .editable-district-row .tools .fill").click(function() {
            changeAmount(this, true);
            return false;
        });
        /**
         * Trigger för tool-knappen "töm" på en grupprad eller en stadsdelsrad beroende
         * på vilken nivå fördelningen görs.
         */
        $("#kp #kp-distribution-list .group-row .tools .clear, #kp #kp-distribution-list .editable-district-row .tools .clear").click(function() {
            changeAmount(this, false);
            return false;
        });
        /**
         * Trigger för tool-knappen "fyll" på en skolrad.
         */
        $("#kp #kp-distribution-list .school-row .tools .fill").click(function() {
            $("." + $(this).parents("tr").attr("id") + " .fill").trigger("click");
            return false;
        });
        /**
         * Trigger för tool-knappen "töm" på en skolrad.
         */
        $("#kp #kp-distribution-list .school-row .tools .clear").click(function() {
            $("." + $(this).parents("tr").attr("id") + " .clear").trigger("click");
            return false;
        });
        /**
         * Trigger för tool-knappen "fyll" på en stadsdelsrad.
         */
        $("#kp #kp-distribution-list .district-row .tools .fill").click(function() {
            $("." + $(this).parents("tr").attr("id") + " .fill").trigger("click");
            return false;
        });
        /**
         * Trigger för tool-knappen "töm" på en stadsdelsrad.
         */
        $("#kp #kp-distribution-list .district-row .tools .clear").click(function() {
            $("." + $(this).parents("tr").attr("id") + " .clear").trigger("click");
            return false;
        });
    });

    $(function() {
        /**
         * Trigger för Ajax-hämtning av skolor när dropdownen för stadsdelar ändras.
         */
        $("#kp #kp-add_group_district_id").change(function() {
            var val = parseInt($(this).val());

            // Disabla övriga fält när man ändrar vald stadsdel
            $("#kp #kp-add_group_school_id, #kp #kp-add_group_group_id, #kp #kp-add-group-submit").attr("disabled", "disabled");

            if (!isNaN(val)) {
                var field = $("#kp #kp-add_group_school_id");

                field.parent().append('<div class="load-indicator"></div>');

                field.load(
                kpConfig.schools.list.url,
                $.param({ 
                    district_id: val
                }),
                function() {
                    $("#kp #kp-add_group_school_id").removeAttr("disabled").
                    parent().find('.load-indicator').remove();
                });
            }
        });
        /**
         * Trigger för Ajax-hämnting av grupper när dropdownen för skolor ändras.
         */
        $("#kp #kp-add_group_school_id").change(function() {
            var val = parseInt($(this).val());

            // Disabla efterföljande fält när man ändrar vald skola.
            $("#kp #kp-add_group_group_id, #kp #kp-add-group-submit").attr("disabled", "disabled");

            if (!isNaN(val)) {
                var field = $("#kp #kp-add_group_group_id");
                field.parent().append('<div class="load-indicator"></div>');

                field.load(
                kpConfig.groups.list.url,
                $.param({
                    school_id: val
                }),
                function() {
                    $("#kp #kp-add_group_group_id").removeAttr("disabled").
                    parent().find('.load-indicator').remove();
                });
            }
        });
        /**
         * Trigger för att enabla/disabla submitknappen när man har valt en grupp.
         */
        $("#kp #kp-add_group_group_id").change(function() {
            var val = parseInt($(this).val());

            if (isNaN(val)) {
                $("#kp #kp-add-group-submit").attr("disabled", "disabled");
            } else {
                $("#kp #kp-add-group-submit").removeAttr("disabled");
            }
        });
    });

    $(function() {
        /**
         * Trigger för att kollapsa/expandera barnen till en stadsdel/skola.
         */
        $("#kp #kp-distribution-list .toggler").click(function() {
            var rows = $("#kp #kp-distribution-list ." + $(this).parents("tr").attr("id"));

            if (rows.is(":visible")) {
                rows.hide();
            } else {
                rows.show();
            }

            return false;
        });
    });
})(jQuery);
