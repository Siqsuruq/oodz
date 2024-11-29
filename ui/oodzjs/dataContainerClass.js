export class dataContainer {
    constructor() {
        this.formData = null;
        this.selectedRows = [];
        this.allTableRows = [];
        this.message = '';
        this.redirectLink = '';
        this.additionalData = {};
    }

    setFormData(formData) {
        this.formData = formData;
    }

    setSelectedRows(rows) {
        this.selectedRows = rows;
    }

    setAllTableRows(rows) {
        this.allTableRows = rows;
    }

    setMessage(message) {
        this.message = message;
    }

    setRedirectLink(link) {
        this.redirectLink = link;
    }

    addCustomData(key, value) {
        this.additionalData[key] = value;
    }

    getAllData() {
        return {
            formData: this.formData,
            selectedRows: this.selectedRows,
            allTableRows: this.allTableRows,
            message: this.message,
            redirectLink: this.redirectLink,
            additionalData: this.additionalData
        };
    }
}
