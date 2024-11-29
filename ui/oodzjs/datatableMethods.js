import { dataContainer } from './dataContainerClass.js';

export function getSelectedRowsData(tableIds, dataContainerInstance) {
    if (!(dataContainerInstance instanceof dataContainer)) {
        throw new Error("Invalid dataContainer instance provided");
    }
    let allSelectedData = {};
    const targetTableIds = tableIds.length ? tableIds : []; // Use all tables by default
    targetTableIds.forEach(tableId => {
        const table = $(`#${tableId}`).DataTable();
        const selectedDataArray = [];
        const selectedData = table.rows('.selected').data();
        selectedData.each(function (value) {
            selectedDataArray.push(value);
        });
        allSelectedData[tableId] = selectedDataArray;
    });
    dataContainerInstance.setSelectedRows(allSelectedData);
    // console.log('Selected data set in dataContainer:', allSelectedData);
    return dataContainerInstance.getAllData();
}


export function getAllRowsData(tableIds, dataContainerInstance) {
    if (!(dataContainerInstance instanceof dataContainer)) {
        throw new Error("Invalid dataContainer instance provided");
    }
    let allData = {};
    const targetTableIds = tableIds.length ? tableIds : []; // Use all tables by default
    targetTableIds.forEach(tableId => {
        const table = $(`#${tableId}`).DataTable();
        const allDataArray = [];
        const data = table.rows().data();
        data.each(function (value) {
            allDataArray.push(value);
        });
        // Store the data in an object using the tableId as the key
        allData[tableId] = allDataArray;
    });
    dataContainerInstance.setAllTableRows(allData);
    // console.log('Data set in dataContainer:', allData);
    return dataContainerInstance.getAllData();
}

export function deleteSelectedRows(tableIds) {
    try {
        const targetTableIds = tableIds.length ? tableIds : [];
        let hasDeletedRows = false; // Flag to check if any rows were deleted

        targetTableIds.forEach(tableId => {
            // Get the DataTable instance by ID
            const table = $(`#${tableId}`).DataTable();
            // Get the selected rows
            const selectedRows = table.rows('.selected');

            if (selectedRows.count() === 0) {
                throw new Error("Please select at least one row to delete.");
            }

            // Remove the rows without additional confirmation
            selectedRows.remove().draw(false);
            hasDeletedRows = true; // Set flag if rows were deleted
        });

        if (!hasDeletedRows) {
            throw new Error("No rows were deleted."); // Throw an error if no rows were deleted
        }

        return "Selected rows have been successfully deleted."; // Return success message
    } catch (error) {
        return error.message; 
    }
}

export function clearTables(tableIds) {
    try {
        const targetTableIds = tableIds.length ? tableIds : [];

        targetTableIds.forEach(tableId => {
            const table = $(`#${tableId}`).DataTable();
            table.clear().draw(); // Clear and redraw the table
        });
    } catch (error) {
        return error.message; 
    }
}