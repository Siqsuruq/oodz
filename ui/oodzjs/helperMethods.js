import { dataContainer } from './dataContainerClass.js';

export function isRequiredFieldFilled(inputElement, form) {
    if (!inputElement || !inputElement.required) {
        return true;
    }

    switch (inputElement.type) {
        case 'file':
            return inputElement.files && inputElement.files.length > 0;
        case 'checkbox':
            return inputElement.checked;
        case 'radio':
            // Check if any radio button with the same name is checked
            const radioGroup = form.querySelectorAll(`[name="${inputElement.name}"]`);
            for (let radio of radioGroup) {
                if (radio.checked) {
                    return true; // At least one radio button is checked
                }
            }
            return false; // No radio buttons are checked
        case 'select-one':
        case 'select-multiple':
            return inputElement.value !== '';
        default:
            return inputElement.value.trim() !== '';
    }
}

export function convertDataContainerToFormData(dataContainerInstance) {
    const formData = new FormData();

    // Append formData if it's already a FormData object
    if (dataContainerInstance.formData instanceof FormData) {
        for (const [key, value] of dataContainerInstance.formData.entries()) {
            formData.append(key, value);
        }
    }

    // Append selectedRows, allTableRows, message, redirectLink, and additionalData
    formData.append("selectedRows", JSON.stringify(dataContainerInstance.selectedRows));
    formData.append("allTableRows", JSON.stringify(dataContainerInstance.allTableRows));
    formData.append("message", dataContainerInstance.message);
    formData.append("redirectLink", dataContainerInstance.redirectLink);
    formData.append("additionalData", JSON.stringify(dataContainerInstance.additionalData));

    return formData;
}

export function convertObjectToFormData(obj) {
    const formData = new FormData();

    for (const key in obj) {
        if (obj.hasOwnProperty(key)) {
            const value = obj[key];

            if (value instanceof File) {
                // If the value is a File object (for uploads)
                formData.append(key, value);
            } else if (typeof value === "object" && value !== null) {
                // If the value is an object (e.g., arrays, nested objects)
                formData.append(key, JSON.stringify(value));
            } else {
                // Otherwise, append as a string
                formData.append(key, value);
            }
        }
    }

    return formData;
}


export function isSuccess(statusCode) {
    return statusCode >= 200 && statusCode < 300;
}

export function isClientError(statusCode) {
    return statusCode >= 400 && statusCode < 500;
}

export function isServerError(statusCode) {
    return statusCode >= 500 && statusCode < 600;
}

export function getBooleanFromStorage(key) {
    return sessionStorage.getItem(key) === 'true';
}