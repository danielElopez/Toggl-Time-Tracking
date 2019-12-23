javascript: (
    function () {
        var APPLY_TO_CURRENT_MONTH = false;
        console.log("Running bookmarklet...");
        /* If applying to current month, add a month offset of -1 to each month */
        var monthOffset = 0;
        if (APPLY_TO_CURRENT_MONTH) {
            monthOffset = 1;
        }
        /* Set the initial status to "scheduled" */
        document.getElementsByClassName('select')[0].click();
        document.getElementsByClassName('select')[0].click();
        document.getElementsByClassName('select')[0].value = "None";
        document.getElementsByClassName('select')[0].innerHTML = "None";
        var desiredSchedulingStatusElement = document.getElementsByClassName('uiMenuItem uiRadioMenuItem')[1];
        desiredSchedulingStatusElement.firstElementChild.click();
        /* Get all inputs, then loop through them */
        var inputs = document.getElementsByClassName(" input");
        /* Define a startindex */
        console.log("Number of input tags found: " + inputs.length);
        var startIndex = inputs.length - 13;
        console.log("Searching starting at index " + startIndex);
        /* Get the current year and month; add one to the month, since it's zero-indexed */
        var currentYear = (new Date()).getFullYear();
        var currentMonth = (new Date()).getMonth() + 1;
        console.log("Current month and year: " + currentMonth + " " + currentYear);
        /* Track the number of date inputs */
        var numberOfDateInputsFound = 0;
        /* Loop through all inputs found... */
        for (var i = startIndex; i < inputs.length; i++) {
            /* See if this input contains a date AND if the next input's id contains "-time" */
            if ((inputs[i].value.indexOf("/" + currentYear) != -1) && (inputs[i + 1].id.indexOf("-time") != -1)) {
                console.log("Date found in input number " + i + "!");
                /* Take note of whether this is one of the first two date inputs found */
                console.log("So far, " + numberOfDateInputsFound + " date inputs have been found");
                /* If the number of date inputs found is 0 or 1, this is one of the first two, and set it to the first day of the prior month */
                var newInputValue = ""; if (numberOfDateInputsFound <= 1) {
                    newInputValue = (currentMonth - 1 - monthOffset) + "/1/" + currentYear;
                    console.log("Setting a start date to " + newInputValue);
                } else {
                    /* Otherwise, set the value to the first day of the current month */
                    newInputValue = (currentMonth - monthOffset) + "/1/" + currentYear;
                    console.log("Setting an end date to " + newInputValue);
                }
                /* Write this new input value to the input */
                inputs[i].value = newInputValue;
                /* Click the input, too, to trigger the animate */
                inputs[i].click();
                /* Now, at the end, add one to the counter that tracks the number of inputs */
                numberOfDateInputsFound = numberOfDateInputsFound + 1;
            }
        }
        /* Also open each calendar */
        var openCalendarButtons = document.getElementsByClassName('datePicker-openIcon display');
        for (var j = 0; j < openCalendarButtons.length; j++) {
            /* Click to open the calendar */
            openCalendarButtons[j].click();
            console.log("Opening calendar...");
            var selectedDate = document.getElementsByClassName("slds-day selectedDate DESKTOP uiDayInMonthCell--default")[0];
            /* Click the first date of the month */
            console.log("Clicking the first of the month button...");
            selectedDate.click();
        }
    }
)();