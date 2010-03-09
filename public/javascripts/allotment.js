(function($) {
    $(function() {
        var form = $("#kp #kp-distribution-form");

        if (form.length <= 0) {
            return;
        }

        form.bind("submit", function() {
            form.find(":submit").attr("disabled", "disabled");
            var cnt = form.find(".submit-cnt");
            cnt.append('<input type="hidden" name="create_tickets" value="1"/>')
            cnt.append('<div class="load-indicator"></div>');
        });

        // Data structure for the allotment state
        var tickets = {
            // Amount of available tickets
            total: parseInt($("#kp #kp-distribution-meta .available-tickets").html()),
            /**
             * Gets tickets from the pool of available tickets.
             *
             * @param num The number of tickets to get
             */
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
            /**
             * Updates the amount of available tickets.
             *
             * @param num The number of tickets to add (or subtract) to the amount
             */
            change: function(num) {
                this.total += num;
                this.updateDisplay();
            },
            /**
             * Updates the UI display with the amount of available tickets
             */
            updateDisplay: function() {
                $("#kp #kp-distribution-meta .available-tickets").html(this.total);
            }
        };

        /**
         * Updates the number of allotted ticket on a district row,
         * based on the number of allotted tickets in child rows
         *
         * @param districtId The id of the district
         */
        function updateDistrictDisplay(districtId) {
            var sum = 0;

            // Sum all group rows that are children to the district
            $("." + districtId + " .num-tickets-value").each(function() {
                var val = parseInt($(this).val());
                if (!isNaN(val))
                    sum += val
            });

            $("#" + districtId + " .num-tickets").html(sum);
        }

        /**
         * Updates the number of allotted ticket on a school row,
         * based on the number of allotted tickets in child rows
         *
         * @param schoolId The id of the school
         */
        function updateSchoolDisplay(schoolId) {
            var sum = 0;

            // Sum all group rows that are children to the district
            $("." + schoolId + " .num-tickets-value").each(function() {
                var val = parseInt($(this).val());
                if (!isNaN(val))
                    sum += val
            });

            $("#" + schoolId + " .num-tickets").html(sum);
        }

        /**
         * Gets the number of children and amount of allotted tickets
         * on a given row.
         *
         * @param row The row the data should be fetched from
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
         * Triggers when the amount of allotted tickets is changed in the hidden
         * value field.
         */
        $("#kp #kp-distribution-list .num-tickets-value").change(function() {
            var field = $(this);
            var row = field.parents("tr");
            var rowData = getRowData(row);

            // Update fill indicator
            row.removeClass("partial full error");

            if (isNaN(rowData.numTickets) || rowData.numTickets < 0) {
                row.addClass("error").attr("title", "Felaktigt antal biljetter");
            } else if (rowData.numTickets > 0 && rowData.numTickets < rowData.numChildren) {
                row.addClass("partial").attr("title", "Gruppen har blivit tilldelad biljetter, men färre än antalet barn i gruppen");
            } else if (rowData.numTickets >= rowData.numChildren) {
                row.addClass("full").attr("title", "Gruppen har blivit tilldelad biljetter så att alla barn i gruppen får en biljett");
            }

            // Update text field
            field.siblings(".num-tickets-display").val(field.val());

            // Update parents
            if (row.hasClass("group-row")) {
                try {
                    updateSchoolDisplay(row.attr("className").match(/kp-school-\d+/)[0]);
                } catch (e) {}
                try {
                    updateDistrictDisplay(row.attr("className").match(/kp-district-\d+/)[0]);
                } catch(e) {}
            }
        });

        /**
         * Triggers when the amount of allotted tickets is changed via the text field
         */
        $("#kp #kp-distribution-list .num-tickets-display").change(function() {
            var field = $(this);
            var newVal = parseInt($(this).val());

            var rowData = getRowData(field.parents("tr"));

            // Update the total amount
            if (!isNaN(newVal) && !isNaN(rowData.numTickets)) {
                tickets.change(rowData.numTickets - newVal);
            } else if (!isNaN(newVal)) {
                tickets.change(0 - newVal);
            } else if (!isNaN(rowData.numTickets)) {
                tickets.change(rowData.numTickets);
            }

            rowData.ticketCnt.val(newVal).trigger("change");
        });


        /**
         * Common function for tool buttons. Fills/clears a row's allotted tickets.
         *
         * @param link The clicked tool button
         * @param fill Indicates if the row should be filled or emptied
         */
        function changeAmount(link, fill) {
            var rowData = getRowData($(link).parents("tr"));

            var tc = 0;

            if (fill) {
                if (rowData.numTickets >= rowData.numChildren) {
                    tc = tickets.getAvailable(1) + rowData.numTickets;
                } else {
                    tc = tickets.getAvailable(rowData.numChildren - rowData.numTickets) + rowData.numTickets;
                }
            } else {
                tickets.change(rowData.numTickets);
            }

            rowData.ticketCnt.val(tc).trigger("change");
        }

        /**
         * Triggers when the "fill" tool button is pressed on a group row or a district
         * row depending on the mode of the allotment.
         */
        $("#kp #kp-distribution-list .group-row .tools .fill, #kp #kp-distribution-list .editable-district-row .tools .fill").click(function() {
            changeAmount(this, true);
            return false;
        });
        /**
         * Triggers when the "clear" tool button is pressed on a group row or a district
         * row depending on the mode of the allotment.
         */
        $("#kp #kp-distribution-list .group-row .tools .clear, #kp #kp-distribution-list .editable-district-row .tools .clear").click(function() {
            changeAmount(this, false);
            return false;
        });
        /**
         * Triggers when the "fill" tool button is pressed on a school row.
         */
        $("#kp #kp-distribution-list .school-row .tools .fill").click(function() {
            $("." + $(this).parents("tr").attr("id") + " .fill").trigger("click");
            return false;
        });
        /**
         * Triggers when the "clear" tool button is pressed on a school row.
         */
        $("#kp #kp-distribution-list .school-row .tools .clear").click(function() {
            $("." + $(this).parents("tr").attr("id") + " .clear").trigger("click");
            return false;
        });
        /**
         * Triggers when the "fill" tool button is pressed on a district row.
         */
        $("#kp #kp-distribution-list .district-row .tools .fill").click(function() {
            $("." + $(this).parents("tr").attr("id") + " .fill").trigger("click");
            return false;
        });
        /**
         * Triggers when the "clear" tool button is pressed on a district row.
         */
        $("#kp #kp-distribution-list .district-row .tools .clear").click(function() {
            $("." + $(this).parents("tr").attr("id") + " .clear").trigger("click");
            return false;
        });

        /**
         * Listeners for group selection fragment events for the allotment form
         */
        $("#kp .allotment-group-selection #kp-group-selection-form"
        ).bind("groupSelected", function(e, groupId) {
            if (isNaN(groupId)) {
                // Disable the form
                $("#kp #kp-add-group-submit").attr("disabled", "disabled");
            } else {
                // Set the group id in the form
                $("#kp #kp-add_group_group_id").val(groupId);
                $("#kp #kp-add-group-submit").removeAttr("disabled");
            }
        }).bind("districtSelected schoolSelected", function(e, id) {
            // Disable the form
            $("#kp #kp-add-group-submit").attr("disabled", "disabled");
        });

        /**
         * Expands/collapses the children of the selected district/school
         */
        $("#kp #kp-distribution-list .toggler").click(function() {
            var toggler = $(this);
            var rows = $("#kp #kp-distribution-list ." + toggler.parents("tr").attr("id"));

            if (rows.is(":visible")) {
                toggler.addClass("collapsed");
                rows.hide();
            } else {
                toggler.removeClass("collapsed");
                rows.show().find(".toggler.collapsed").removeClass("collapsed");
            }

            return false;
        });
    });

    $(function() {
        /**
         * Ping function to prevent session timeout.
         */
        setInterval(function(){
            $.get(kpConfig.ping.url);
        }, 300000);
    });


})(jQuery);
