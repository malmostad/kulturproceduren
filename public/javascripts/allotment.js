(function($) {
    $(function() {

        var tickets = {
            total: parseInt($("#kp #kp-distribution-meta .available-tickets").html()),
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
            change: function(num) {
                this.total += num;
                this.updateDisplay();
            },
            updateDisplay: function() {
                $("#kp #kp-distribution-meta .available-tickets").html(this.total);
            }
        };

        function updateDistrictDisplay(districtId) {
            var sum = 0;

            $("." + districtId + " .num-tickets-value").each(function() {
                sum += parseInt($(this).val());
            });

            $("#" + districtId + " .num-tickets").html(sum);
        }

        function updateSchoolDisplay(schoolId) {
            var sum = 0;

            $("." + schoolId + " .num-tickets-value").each(function() {
                sum += parseInt($(this).val());
            });

            $("#" + schoolId + " .num-tickets").html(sum);
        }


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

        $("#kp #kp-distribution-list .num-tickets-value").change(function() {
            var field = $(this);
            var row = field.parents("tr");
            var rowData = getRowData(row);

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

            field.siblings(".num-tickets-display").val(field.val());

            if (field.hasClass("group-row")) {
                try {
                    updateSchoolDisplay(row.attr("className").match(/kp-school-\d+/)[0]);
                } catch (e) {}
                try {
                    updateDistrictDisplay(row.attr("className").match(/kp-district-\d+/)[0]);
                } catch(e) {}
            }
        });

        $("#kp #kp-distribution-list .num-tickets-display").change(function() {
            var field = $(this);
            var newVal = parseInt($(this).val());
            var rowData = getRowData(field.parents("tr"));

            tickets.change(rowData.numTickets - newVal);
            rowData.ticketCnt.val(newVal).trigger("change");
        });


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

        $("#kp #kp-distribution-list .group-row .tools .fill, #kp #kp-distribution-list .editable-district-row .tools .fill").click(function() {
            changeAmount(this, true);
            return false;
        });
        $("#kp #kp-distribution-list .group-row .tools .clear, #kp #kp-distribution-list .editable-district-row .tools .clear").click(function() {
            changeAmount(this, false);
            return false;
        });
        $("#kp #kp-distribution-list .school-row .tools .fill").click(function() {
            $("." + $(this).parents("tr").attr("id") + " .fill").trigger("click");
            return false;
        });
        $("#kp #kp-distribution-list .school-row .tools .clear").click(function() {
            $("." + $(this).parents("tr").attr("id") + " .clear").trigger("click");
            return false;
        });
        $("#kp #kp-distribution-list .district-row .tools .fill").click(function() {
            $("." + $(this).parents("tr").attr("id") + " .fill").trigger("click");
            return false;
        });
        $("#kp #kp-distribution-list .district-row .tools .clear").click(function() {
            $("." + $(this).parents("tr").attr("id") + " .clear").trigger("click");
            return false;
        });
    });

    $(function() {
        $("#kp #kp-add_group_district_id").change(function() {
            var val = parseInt($(this).val());

            if (isNaN(val)) {
                $("#kp #kp-add_group_school_id, #kp #kp-add_group_group_id, #kp #kp-add-group-submit").attr("disabled", "disabled");
            } else {
                $("#kp #kp-add_group_school_id").load(
                kpConfig.schools.list.url,
                $.param({ 
                    district_id: val
                }),
                function () {
                    $("#kp #kp-add_group_school_id").removeAttr("disabled");
                });
            }
        });
        $("#kp #kp-add_group_school_id").change(function() {
            var val = parseInt($(this).val());

            if (isNaN(val)) {
                $("#kp #kp-add_group_group_id, #kp #kp-add-group-submit").attr("disabled", "disabled");
            } else {
                $("#kp #kp-add_group_group_id").load(
                kpConfig.groups.list.url,
                $.param({
                    school_id: val
                }),
                function () {
                    $("#kp #kp-add_group_group_id").removeAttr("disabled");
                });
            }
        });
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
