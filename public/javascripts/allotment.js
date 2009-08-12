(function($) {
    $(function() {

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
                sum += parseInt($(this).val());
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
                sum += parseInt($(this).val());
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

            if (rowData.numTickets == NaN || rowData.numTickets < 0) {
                row.addClass("error");
            } else if (rowData.numTickets > 0 && rowData.numTickets < rowData.numChildren) {
                row.addClass("partial");
            } else if (rowData.numTickets >= rowData.numChildren) {
                row.addClass("full");
            }

            // Update text field
            field.siblings(".num-tickets-display").val(field.val());

            // Update parents
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
         * Triggers when the amount of allotted tickets is changed via the text field
         */
        $("#kp #kp-distribution-list .num-tickets-display").change(function() {
            var field = $(this);
            var newVal = parseInt($(this).val());
            var rowData = getRowData(field.parents("tr"));

            // Update the total amount
            tickets.change(rowData.numTickets - newVal);
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
    });

    $(function() {
        /**
         * Ajax functionality for fetching a district's schools when the chosen
         * district is changed.
         */
        $("#kp #kp-add_group_district_id").change(function() {
            var val = parseInt($(this).val());

            // Disable all subsequent fields when changing district
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
         * Ajax functionality for fetching a school's groups when the
         * chosen school is changed.
         */
        $("#kp #kp-add_group_school_id").change(function() {
            var val = parseInt($(this).val());

            // Disable all subsequent fields when changing school
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
         * Enables/disables the submit button when the selected group is changed.
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
         * Expands/collapses the children of the selected district/school
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
