import { dataContainer } from './dataContainerClass.js';
import { getSelectedRowsData, getAllRowsData, deleteSelectedRows, clearTables } from './datatableMethods.js';
import { isRequiredFieldFilled, convertDataContainerToFormData, isSuccess, isClientError, isServerError, getBooleanFromStorage } from './helperMethods.js';
import { getFormData,clearForm,updateFormValues,resetForm } from './formMethods.js';
import { parseServerResponse } from './responseParser.js';
import { visibilityMethods } from './visibility.js';

export class formData {
	constructor(formId) {
		this.form = document.getElementById(formId);
        if (this.form) {
            this.apiUrl = this.form.getAttribute('data-api-url');
        } else {
            console.error(`Form with ID ${formId} not found.`);
            return;
        }
		// Initialize DataTables and store their IDs in array
        this.tables = $(this.form).find('.oodz_tbl').DataTable();
        this.tableIds = $(this.form).find('.oodz_tbl').map(function() {
            return this.id;
        }).get();

        // this.hideElements = (selector) => visibilityMethods.hideElements(selector, this.form);
		// this.unhideElements = (selector) => visibilityMethods.unhideElements(selector, this.form);
		// this.disableElements = (selector) => visibilityMethods.disableElements(selector, this.form);
		// this.enableElements = (selector) => visibilityMethods.enableElements(selector, this.form); 
		// this.readonlyElements = (selector) => visibilityMethods.readonlyElements(selector, this.form);
		// this.notreadonlyElements = (selector) => visibilityMethods.notreadonlyElements(selector, this.form); 

        this.isSubmitting = false;
        this.dataContainer = new dataContainer();
        this.#initModalEvents();
        // Handle toast after redirect
        this.#checkForToastMessage();
	}

    #checkForToastMessage() {
        document.addEventListener('DOMContentLoaded', () => {
            this.#showStoredToastMessage(true);
        });
    }
    
    // New method to show the toast immediately
    #showStoredToastMessage(redirect = false) {
        const toastMessage = sessionStorage.getItem('toastMessage');
        const toastStatus = sessionStorage.getItem('toastStatus');
        const showAfterRedirect = getBooleanFromStorage('showafterredirect');
        if (showAfterRedirect === redirect) {
            if (toastMessage && toastStatus) {
                showToast(toastMessage, toastStatus);
                // Clear the stored message after displaying
                sessionStorage.removeItem('toastMessage');
                sessionStorage.removeItem('toastStatus');
                sessionStorage.removeItem('showafterredirect');
            }
        }
    }

	async sendAllData(apiUrl = this.apiUrl, ids = [], useCaptcha = false) {
        if (this.isSubmitting) {
            showToast('Submission already in progress.', 'warning');
            return;
        }
    
        if (!apiUrl) {
            showToast('Invalid API URL.', 'error');
            return;
        }
        this.isSubmitting = true;

		try {
            this.#getAllData(ids);
            //showToast(`Sending data to: ${apiUrl} with IDs: ${ids.length > 0 ? ids.join(', ') : 'all'}`, 'info');

            // Send the data to the server
            const result = await this.#sendDataToServer(apiUrl);
            if (result.redirect_url) {
                console.log("Redirecting to:", result.redirect_url);
                window.location.href = result.redirect_url; // Perform the redirect
            }
            if (isSuccess(result.code)) {
                updateFormValues(result.data, this.form);
                // Handle file downloads
                if (result.isFile) {
                    const fileUrl = URL.createObjectURL(result.data);
                    const a = document.createElement('a');
                    a.href = fileUrl;

                    // Extract the filename from Content-Disposition
                    const contentDisposition = result.headers.get('Content-Disposition');
                    const fileName = contentDisposition
                        ? contentDisposition.split('filename=')[1].split(';')[0].replace(/"/g, '')
                        : 'downloaded_file';

                    a.download = fileName;
                    a.click();
                    URL.revokeObjectURL(fileUrl); // Clean up the URL object

                    console.log(`File "${fileName}" downloaded successfully.`);
                }
            } else if (isClientError(result.code)) {
                showToast(result.details, 'error');
            } else if (isServerError(result.code)) {
                showToast(result.details, 'error');
            } else {
                showToast(result.details, 'error');
                console.error("Unexpected response:", result);
            }
		} catch (error) {
            showToast(error.message, 'error');
        } finally {
            // Unlock the submission after the operation
            this.isSubmitting = false;
            this.#showStoredToastMessage();
        }
	}


    async #sendDataToServer(apiUrl, config = {}) {
        const formData = convertDataContainerToFormData(this.dataContainer);
        const defaultConfig = {
            method: 'POST',
            body: formData,
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('apikey')}`, // Retrieve the API key
            },
        };
    
        try {
            const response = await fetch(apiUrl, { ...defaultConfig, ...config });
            const parsedResponse = await parseServerResponse(response);
            return parsedResponse;
        } catch (error) {
            console.error("Network or server error occurred:", error);
            throw error; 
        }
    }

    #getAllData(ids = []) {
        try {
            getFormData(this.form, ids, this.dataContainer);
            getAllRowsData(this.tableIds, this.dataContainer);
            getSelectedRowsData(this.tableIds, this.dataContainer);
        } catch (error) {
            throw error;
        }
    }

    resetForm(event) {
        this.isSubmitting = false;
        resetForm(this.form, event);
    }

    clearForm(ids =[], form = this.form) {
        clearForm(form, ids);
    }

    // DataTables methods
    deleteSelectedRows() {
        // Show the Bootstrap modal for confirmation
        $('#deleteConfirmationModal').modal('show');
    }

    clearAllTables() {
        const errorMessage = clearTables(this.tableIds);
        if (errorMessage) {
            showToast(errorMessage, 'error');
        }
    }

    // Initialize modal events
    #initModalEvents() {
        // Check if the modal and table elements exist
        const deleteModal = document.getElementById('deleteConfirmationModal');
        const confirmDeleteButton = document.getElementById('confirmDeleteButton');

        if (!deleteModal || !confirmDeleteButton || !this.tableIds || this.tableIds.length === 0) {
            //console.warn('Modal or tables are not present, skipping modal event initialization.');
            return;
        }

        // Handle the delete confirmation
        confirmDeleteButton.addEventListener('click', () => {
            // Perform deletion
            const result = deleteSelectedRows(this.tableIds);
            if (result.includes("successfully")) {
                showToast(result, 'success'); // Show success toast
            } else {
                showToast(result, 'error'); // Show error toast
            }
            // Hide the modal after confirmation
            $('#deleteConfirmationModal').modal('hide');
        });
    }

    
}


/* Toastify helper function */
function showToast(message, type) {
	Toastify({
		text: message,
		duration: 5000,
		close: true,
		gravity: "top", 
		position: 'right',
		className: 'toast-' + type,
		stopOnFocus: true
	}).showToast();
}