/**
 * Parses the server response and handles potential redirects.
 * @param {Response} response - The fetch Response object.
 * @returns {Object} An object containing parsed data, status, error (if any), and redirectUrl (if provided).
 */
export async function parseServerResponse(response) {
    const result = {
        statusCode: response.status,           // HTTP status code
        data: null,                            // Parsed response body
        error: null,                           // Structured error details
        headers: response.headers,             // Include headers if needed
        redirect_url: null,                    // Add redirect_url at the top level
        isFile: false,                         // Flag for file downloads
    };

    try {
        // Detect if the response is a file (Content-Disposition header)
        const contentDisposition = response.headers.get('Content-Disposition');
        if (contentDisposition && contentDisposition.includes('attachment')) {
            result.isFile = true;
            result.data = await response.blob(); // Retrieve file as Blob
            return result; // No further parsing needed for files
        }

        // Read the response body as text first
        const responseText = await response.text();

        // Try to parse the text as JSON
        try {
            const responseBody = JSON.parse(responseText);
            result.data = responseBody;
            result.redirect_url = responseBody.redirect_url || null;

            // Extract top-level fields: status and details
            const status = responseBody?.status?.toLowerCase(); // Ensure it's lowercase
            const details = responseBody?.details;

            // Handle toast messages based on status
            const validStatuses = ['success', 'warning', 'error', 'info'];
            if (validStatuses.includes(status)) {
                if (details) {
                    sessionStorage.setItem('toastMessage', details);
                    sessionStorage.setItem('toastStatus', status);
                } else {
                    sessionStorage.removeItem('toastMessage'); // Clear any previously set message
                    sessionStorage.removeItem('toastStatus'); // Clear any previously set status
                }
            }
        } catch (jsonError) {
            // JSON parsing failed; treat the body as plain text
            result.data = responseText;
            result.error = "Failed to parse JSON response.";
        }

        // Backend-handled redirect (302 with Location header)
        if (result.statusCode >= 300 && result.statusCode < 400) {
            const location = result.headers.get('Location');
            if (location) {
                result.redirect_url = location; 
            }
        }
    } catch (error) {
        // Catch and log unexpected errors
        console.error("Error parsing server response:", error);
        result.error = result.error
            ? `${result.error}; Additional Error: ${error.message}`
            : error.message;
    }

    // Return the processed result
    return result;
}