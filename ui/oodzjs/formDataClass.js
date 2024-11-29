import { dataContainer } from './dataContainerClass.js';
import { getSelectedRowsData, getAllRowsData, deleteSelectedRows, clearTables } from './datatableMethods.js';
import { isRequiredFieldFilled, convertDataContainerToFormData, isSuccess, isClientError, isServerError } from './helperMethods.js';
import { getFormData,clearForm,updateFormValues } from './formMethods.js';
import { parseServerResponse } from './responseParser.js';

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

        this.isSubmitting = false;
        this.dataContainer = new dataContainer();
        this.#initModalEvents();
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
            showToast(`Sending data to: ${apiUrl} with IDs: ${ids.length > 0 ? ids.join(', ') : 'all'}`, 'info');

            // Send the data to the server
            const result = await this.#sendDataToServer(apiUrl);
            
            if (isSuccess(result.statusCode)) {
                console.log("Success:", result.data);
            } else if (isClientError(result.statusCode)) {
                console.warn("Client error:", result.error || "Something went wrong with your request.");
            } else if (isServerError(result.statusCode)) {
                showToast(error.message, 'error');
                console.error("Server error:", result.error || "The server encountered an issue.");
            } else {
                showToast(error.message, 'error');
                console.error("Unexpected response:", result);
            }
            if (result.redirect_url) {
                console.log("Redirecting to:", result.redirect_url);
                window.location.href = result.redirect_url; // Perform the redirect
            }
            
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
            updateFormValues(result.data.data);
		} catch (error) {
            showToast(error.message, 'error');
        } finally {
            // Unlock the submission after the operation
            this.isSubmitting = false;
        }
	}


    async #sendDataToServer(apiUrl, config = {}) {
        const formData = convertDataContainerToFormData(this.dataContainer);
        const defaultConfig = {
            method: 'POST',
            body: formData,
        };
    
        try {
            const response = await fetch(apiUrl, { ...defaultConfig, ...config });
            const parsedResponse = await parseServerResponse(response);
            return parsedResponse;
        } catch (error) {
            console.error("Network or server error occurred:", error);
            return {
                statusCode: null,
                data: null,
                error: error.message,
                headers: {},
                redirect_url: null,
            };
        }
    }

    #getAllData(ids = []) {
        try {
            if (ids.length === 0) {
                getFormData(this.form, ids, this.dataContainer);
                getAllRowsData(this.tableIds, this.dataContainer);
                getSelectedRowsData(this.tableIds, this.dataContainer);
            } else {

            }
        } catch (error) {
            throw error;
        }
    }

    clearForm(event) {
        clearForm(this.form, event);
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
        // Handle the delete confirmation
        document.getElementById('confirmDeleteButton').addEventListener('click', () => {
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
//Test cache
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