import { dataContainer } from './dataContainerClass.js';
import { isRequiredFieldFilled } from './helperMethods.js';

// export function getFormData(form, ids, dataContainerInstance) {
//     if (!(dataContainerInstance instanceof dataContainer)) {
//         throw new Error("Invalid dataContainer instance provided");
//     }
//     try {
//         const filteredData = new FormData();
//         const inputElements = ids.length > 0
//             ? ids.map(id => form.querySelector(`#${id}`)).filter(Boolean) // Filter out nulls
//             : Array.from(form.querySelectorAll('input, select, textarea'));

//         // Validate fields
//         const firstInvalidField = inputElements.find(inputElement =>
//             inputElement.required && !isRequiredFieldFilled(inputElement, form)
//         );

//         if (firstInvalidField) {
//             const fieldLabel = firstInvalidField.placeholder || firstInvalidField.name || "Unknown Field";
//             throw new Error(`Field '${fieldLabel}' is required and not filled.`);
//         }

//         // Populate valid fields into FormData
//         inputElements.forEach(inputElement => {
//             // console.log("element: " + inputElement.id);
//             if (!inputElement.name) {
//                 // Skip fields without a name attribute (e.g., Bootstrap caption input)
//                 return;
//             }
//             if (inputElement.type === 'file' && inputElement.files.length > 0) {
//                 filteredData.append(inputElement.name, inputElement.files[0]);
//             } else if (inputElement.type === 'checkbox') {
//                 if (inputElement.checked) {
//                     filteredData.append(inputElement.name, inputElement.value);
//                 } else {
//                     // Get the hidden input with the same name
//                     const hiddenInput = form.querySelector(`input[type="hidden"][name="${inputElement.name}"]`);
//                     if (hiddenInput) {
//                         filteredData.append(hiddenInput.name, hiddenInput.value);
//                     } else {
//                         // Fallback if no hidden input present
//                         filteredData.append(inputElement.name, "0");
//                     }
//                 }
//             } else if (inputElement.type !== 'radio' || inputElement.checked) {
//                 filteredData.append(inputElement.name, inputElement.value);
//             }
//         });

//         // Update the data container with the filtered data
//         dataContainerInstance.setFormData(filteredData);
//     } catch (error) {
//         console.error(error);
//         throw error;
//     }
// }

export function getFormData(defaultForm, ids = [], dataContainerInstance) {
    if (!(dataContainerInstance instanceof dataContainer)) {
        throw new Error("Invalid dataContainer instance provided");
    }

    try {
        const filteredData = new FormData();

        // --- Case 1: No IDs provided, collect ALL from default form ---
        if (ids.length === 0) {
            const elements = defaultForm.querySelectorAll('input, select, textarea');
            elements.forEach(input => {
                if (!input.name) return;
                if (input.type === 'file' && input.files.length > 0) {
                    filteredData.append(input.name, input.files[0]);
                } else if (input.type === 'checkbox') {
                    filteredData.append(input.name, input.checked ? input.value : '0');
                } else if (input.type !== 'radio' || input.checked) {
                    filteredData.append(input.name, input.value);
                }
            });

            dataContainerInstance.setFormData(filteredData);
            return;
        }

        // --- Case 2: Group by form ID when dot notation used ---
        const grouped = {};

        ids.forEach(id => {
            if (id.includes('.')) {
                const [formId, fieldId] = id.split('.');
                if (!grouped[formId]) grouped[formId] = [];
                grouped[formId].push(fieldId);
            } else {
                if (!grouped['__default__']) grouped['__default__'] = [];
                grouped['__default__'].push(id);
            }
        });

        for (const formId in grouped) {
            const fieldIds = grouped[formId];
            const form = formId === '__default__' ? defaultForm : document.getElementById(formId);

            if (!form) {
                console.warn(`Form with ID "${formId}" not found.`);
                continue;
            }

            if (fieldIds.includes('*')) {
                // Collect all inputs from that form
                const elements = form.querySelectorAll('input, select, textarea');
                elements.forEach(input => {
                    if (!input.name) return;
                    if (input.type === 'file' && input.files.length > 0) {
                        filteredData.append(input.name, input.files[0]);
                    } else if (input.type === 'checkbox') {
                        filteredData.append(input.name, input.checked ? input.value : '0');
                    } else if (input.type !== 'radio' || input.checked) {
                        filteredData.append(input.name, input.value);
                    }
                });
            } else {
                // Specific fields from this form
                fieldIds.forEach(fieldId => {
                    const input = form.querySelector(`#${fieldId}, [name="${fieldId}"]`);
                    if (input && input.name) {
                        if (input.type === 'file' && input.files.length > 0) {
                            filteredData.append(input.name, input.files[0]);
                        } else if (input.type === 'checkbox') {
                            filteredData.append(input.name, input.checked ? input.value : '0');
                        } else if (input.type !== 'radio' || input.checked) {
                            filteredData.append(input.name, input.value);
                        }
                    } else {
                        console.warn(`Field "${fieldId}" not found in form "${formId}"`);
                    }
                });
            }
        }

        dataContainerInstance.setFormData(filteredData);
    } catch (error) {
        console.error(error);
        throw error;
    }
}



// Function to update form values and optionally clear specific components
export function updateFormValues(data, form) {
    console.log("Received Data Type:", typeof data);
    console.log("Received Data:", data);

    let recievedData;
    try {
        recievedData = typeof data === "string" ? JSON.parse(data) : data; // Convert string to object
        console.log("Parsed JSON:", recievedData);
    } catch (error) {
        console.error("Invalid JSON:", error);
        return; // Exit the function if JSON is invalid
    }

    // Debugging: Check if 'componentsToClear' exists
    console.log("Checking componentsToClear:", recievedData.componentsToClear);

    // Check if 'componentsToClear' exists in the parsed data and call 'clearForm'
    if (recievedData.componentsToClear && Array.isArray(recievedData.componentsToClear)) {
        console.log("Clearing components:", recievedData.componentsToClear);
        clearForm(form, recievedData.componentsToClear);
        delete recievedData.componentsToClear; // Remove it to prevent unintended updates
    }

    // Debugging: Confirm remaining data keys
    console.log("Updating elements for keys:", Object.keys(recievedData));

    // Iterate over the remaining keys to update elements
    Object.keys(recievedData).forEach(key => {
        const elmnt = document.getElementById(key);
        if (elmnt) {
            console.log(`Updating element ${key} with value`, recievedData[key]);
            updateElement(elmnt, recievedData[key]);
        } else {
            console.warn(`Element with ID '${key}' not found.`);
        }
    });
}


export function updateElement(elmnt, value) {
    console.log(`Updating element with ID: ${elmnt.id}, Type: ${elmnt.type}, Tag: ${elmnt.tagName}, Value: ${value}`);
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
        $("#" + elmnt.id).val('-1');
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

// Dynamically detect and update any table
function updateTable(elmnt, data) {
    if (!$.fn.DataTable.isDataTable("#" + elmnt.id)) {
        console.warn(`Skipping update for '${elmnt.id}' because it's not a DataTable.`);
        return;
    }

    const table = $("#" + elmnt.id).DataTable();
    table.clear(); // Remove existing rows

    if (Array.isArray(data)) {
        table.rows.add(data).draw(); // Add multiple rows
    } else {
        console.warn(`Expected an array for table '${elmnt.id}', but got:`, data);
    }
}

// Clear form method, will clear all values, defaults, dropdowns and tables
export function clearForm(form, ids = []) {
    // Get the form element if a form ID is provided
    const formElement = typeof form === 'string' ? document.getElementById(form) : form;

    if (!formElement) {
        console.error('Form not found:', form);
        return;
    }

    // If no IDs are provided, get all form elements
    if (ids.length === 0) {
        ids = Array.from(formElement.elements).map(el => el.id).filter(id => id);
    }

    ids.forEach(id => {
        // console.log(`Clearing element with ID: ${id}`);
        const element = document.getElementById(id);

        if (element) {
            // Check if the element is a modal and close it
            if (element.classList.contains('modal')) {
                $(element).modal('hide');
            }
            switch (element.tagName.toLowerCase()) {
                case 'input':
                    clearInputElement(element);
                    break;
                case 'select':
                    $(element).val(null).trigger('change');
                    $(element).empty().trigger('change');
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
}

// Helper function to clear different types of input elements
function clearInputElement(element) {
    switch (element.type) {
        case 'checkbox':
        case 'radio':
            element.checked = false;
            break;
        case 'date':
        case 'time':
        case 'number':
        case 'text':
        case 'email':
        case 'password':
        case 'tel':
        case 'url':
            element.value = '';
            break;
        default:
            console.warn(`Unsupported input type: ${element.type} for element with ID: ${element.id}`);
    }
}


export function resetForm(form, event) {
    console.log('Resetting form:', form);
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
        $(this).val('-1').trigger('change.select2');
    });
}