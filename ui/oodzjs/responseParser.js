/**
 * Parses the server response and handles potential redirects.
 * @param {Response} response - The fetch Response object.
 * @returns {Object} An object containing parsed data, status, error (if any), and redirect_url (if provided).
 */
export async function parseServerResponse(response) {
    const result = {
        code: response.status,                 // HTTP status code
        version: null,
        currentTime: null,
        method: null,
        request: null,
        status: null,
        details: "",
        data: null,                            // Parsed response body
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
        // Backend-handled redirect (302 with Location header)
        if (result.code >= 300 && result.code < 400) {
            // Handle redirect URL from Location header
            const location = result.headers?.get('Location'); // Safe access
            result.redirect_url = location || null;
        }

        // Read the response body as text first
        const responseText = await response.text();

        // Try to parse the text as JSON
        try {
            const responseBody = JSON.parse(responseText);
            result.version = responseBody.version || null;
            result.currentTime = responseBody.currentTime || null;
            result.method = responseBody.method || null;
            result.request = responseBody.request || null;
            result.status = responseBody.status || null;
            result.details = responseBody.details || "";
            result.data = responseBody.data || null;
            if (responseBody.redirect_url) {
                // Check if result.redirect_url is null or empty
                if (!result.redirect_url || result.redirect_url.trim() === "") {
                    // Assign responseBody.redirect_url to result.redirect_url
                    result.redirect_url = responseBody.redirect_url;
                }
            }
            
            // Handle toast messages based on status
            const validStatuses = ['success', 'warning', 'error', 'info'];
            if (validStatuses.includes(result.status.toLowerCase())) {
                if (result.details) {
                    sessionStorage.setItem('toastMessage', result.details);
                    sessionStorage.setItem('toastStatus', result.status.toLowerCase());
                    if (result.redirect_url) {
                        sessionStorage.setItem('showafterredirect', true);
                    } else {
                        sessionStorage.setItem('showafterredirect', false);
                    }
                } else {
                    sessionStorage.removeItem('toastMessage'); 
                    sessionStorage.removeItem('toastStatus');
                    sessionStorage.removeItem('showafterredirect');
                }
            }
        } catch (jsonError) {
            // JSON parsing failed; treat the body as plain text
            result.data = responseText;
            result.error = "Failed to parse JSON response.";
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