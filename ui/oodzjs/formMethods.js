import { dataContainer } from './dataContainerClass.js';
import { isRequiredFieldFilled } from './helperMethods.js';

export function getFormData(form, ids, dataContainerInstance) {
    if (!(dataContainerInstance instanceof dataContainer)) {
        throw new Error("Invalid dataContainer instance provided");
    }
    try {
        const filteredData = new FormData();
        const inputElements = ids.length > 0
            ? ids.map(id => form.querySelector(`#${id}`)).filter(Boolean) // Filter out nulls
            : Array.from(form.querySelectorAll('input, select, textarea'));

        // Validate fields
        const firstInvalidField = inputElements.find(inputElement =>
            inputElement.required && !isRequiredFieldFilled(inputElement, form)
        );

        if (firstInvalidField) {
            const fieldLabel = firstInvalidField.placeholder || firstInvalidField.name || "Unknown Field";
            throw new Error(`Field '${fieldLabel}' is required and not filled.`);
        }

        // Populate valid fields into FormData
        inputElements.forEach(inputElement => {
            if (inputElement.type === 'file' && inputElement.files.length > 0) {
                filteredData.append(inputElement.name, inputElement.files[0]);
            } else if (inputElement.type === 'checkbox' && inputElement.checked) {
                filteredData.append(inputElement.name, inputElement.value);
            } else if (inputElement.type !== 'radio' || inputElement.checked) {
                filteredData.append(inputElement.name, inputElement.value);
            }
        });

        // Update the data container with the filtered data
        dataContainerInstance.setFormData(filteredData);
    } catch (error) {
        throw error;
    }
}

export function clearForm(form, event) {
    if (event) {
        event.preventDefault();
    }
    // Reset the form
    form.reset();
    // Find all tables within the form and deselect all rows, clear search and redraw
    $(form).find('table').each(function() {
        var table = $(this).DataTable();
        table.rows().deselect();
        table.search('').draw();
    });
    // Clear all oodz_select widgets within the form
    $(form).find('.oodz_select').each(function() {
        $(this).val('default').trigger('change.select2');
    });
}

export function updateFormValues(data) {
    console.log("DATA TO UPDATE: " + JSON.stringify(data));
    Object.keys(data).forEach(key => {
        const elmnt = document.getElementById(key);
        if (elmnt) {
            updateElement(elmnt, data[key]);
        }
    });
}

export function updateElement(elmnt, value) {
    console.log(`Updating element with ID: ${elmnt.id}, Type: ${elmnt.type}, Tag: ${elmnt.tagName}, Value: ${value}`);
    console.log(value);
    if (elmnt.type === "checkbox" || elmnt.type === "radio") {
        // elmnt.checked = value ? true : false;
        elmnt.checked = !!value;
    } else if (["text", "password", "textarea", "date", "month", "week", "time", "datetime-local", "number", "range", "search", "tel", "url", "email", "color", "hidden"].includes(elmnt.type)) {
        elmnt.value = value;
    } else if (elmnt.classList.contains('oodz_select')) {
        // Convert the object to an array of key-value pairs
        Object.entries(value).forEach(([key, text]) => {
            $("#" + elmnt.id).append(new Option(text, key));
        });	
        $("#" + elmnt.id).trigger('change.select2');
    } else if (elmnt.classList.contains('oodz_tbl')) {
        var table = $("#" + elmnt.id).DataTable();
        // Check if 'value' is an array
        if (Array.isArray(value)) {
            table.rows.add(value).draw(); // Add multiple rows
        } 
        // Check if 'value' is an object with property 'id'
        else if (value && typeof value === "object" && value.hasOwnProperty('id')) {
            table.row.add(value).draw(); // Add a single row
        } else {
            console.log("Who knows what type weve got");
        }
    }  else if (elmnt.type !== "hidden") {
        elmnt.value = value;
    }
}

export function resetForm(form, ids = []) {
    // Get the form element if a form ID is provided
    const formElement = typeof form === 'string' ? document.getElementById(form) : form;

    if (!formElement) {
        console.error('Form not found:', form);
        return;
    }

    ids.forEach(id => {
        const element = formElement.querySelector(`#${id}`);
        if (element) {
            switch (element.tagName.toLowerCase()) {
                case 'input':
                    if (element.type === 'checkbox' || element.type === 'radio') {
                        element.checked = false;
                    } else {
                        element.value = '';
                    }
                    break;
                case 'select':
                    element.selectedIndex = 0; // Reset to the first option
                    $(element).trigger('change.select2'); // Trigger Select2 change if applicable
                    break;
                case 'textarea':
                    element.value = '';
                    break;
                default:
                    console.warn(`Unsupported element type: ${element.tagName} for ID: ${id}`);
            }
        } else {
            console.warn(`Element with ID "${id}" not found in the specified form.`);
        }
    });

    console.log('Form elements reset in form:', formElement.id, ids);
}